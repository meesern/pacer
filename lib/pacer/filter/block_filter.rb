module Pacer
  module Routes
    module RouteOperations
      def select(&block)
        chain_route :filter => :block, :block => block, :route_name => 'Select'
      end

      def reject(&block)
        chain_route :filter => :block, :block => block, :invert => true, :route_name => 'Reject'
      end
    end
  end

  module Filter
    module BlockFilter
      def self.triggers
        [:block]
      end

      attr_accessor :block, :invert

      protected

      def attach_pipe(end_pipe)
        pipe = Pacer::Pipes::BlockFilterPipe.new(self, block, invert)
        pipe.set_starts end_pipe
        pipe
      end
    end
  end
end