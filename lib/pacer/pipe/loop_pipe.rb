module Pacer::Pipes
  class LoopPipe < RubyPipe
    import java.util.ArrayList

    def initialize(graph, looping_pipe, control_block)
      super()
      @graph = graph
      @control_block = control_block
      @wrapper = Pacer::Wrappers::WrapperSelector.build

      @expando = ExpandablePipe.new
      empty = ArrayList.new
      @expando.setStarts empty.iterator
      looping_pipe.setStarts(@expando)
      looping_pipe.enablePath true if looping_pipe.respond_to? :enablePath
      @looping_pipe = looping_pipe
    end

    def next
      super
    ensure
      @path = @next_path
    end

    def setStarts(starts)
      if starts.respond_to? :getCurrentPath
        @starts_has_path = true
        starts.enablePath true
      end
      super
    end

    protected

    attr_reader :wrapper, :control_block, :expando, :looping_pipe, :graph, :starts_has_path

    def processNextStart
      while true
        # FIXME: hasNext shouldn't be raising an exception...
        has_next = looping_pipe.hasNext rescue nil
        if has_next
          element = looping_pipe.next
          depth = (expando.metadata || 0) + 1
          @next_path = looping_pipe.getCurrentPath
        else
          element = starts.next
          if starts_has_path
            @next_path = starts.getCurrentPath
          else
            @next_path = ArrayList.new
            @next_path.add element
          end
          depth = 0
        end
        wrapped = wrapper.new(element)
        wrapped.graph = graph if wrapped.respond_to? :graph=
        case control_block.call wrapped, depth, @next_path
        when :loop
          expando.add element, depth, @next_path
        when :emit
          return element
        when :emit_and_loop, :loop_and_emit
          expando.add element, depth, @next_path
          return element
        when false, nil
        else
          expando.add element, depth, @next_path
          return element
        end
      end
    end

    def getPathToHere
      path = ArrayList.new
      if @path
        @path.each do |e|
          path.add e
        end
      end
      path
    end
  end
end
