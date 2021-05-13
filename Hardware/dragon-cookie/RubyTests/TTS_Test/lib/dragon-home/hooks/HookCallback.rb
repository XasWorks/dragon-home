
require 'timeout'

module XNM
    module DragonHome
        class HookCallback
            def initialize(tag, block)
                raise ArgumentError, "Callback tag must be sym or string!" unless (tag.is_a?(Symbol) || tag.is_a?(String))
                
                @block = block;
                @tag   = tag;

                @exec_count = 0;
                @err_count  = 0;

                @exec_time  = 0;

                @disable_until = Time.at(0)
            end


            def execute!(args)
                args = [args].flatten unless args.is_a? Array

                return if Time.now() < @disable_until

                t_start = Time.now();

                begin
                    Timeout.timeout(3) {
                        @block.call(*args)
                    }
                #rescue
                #   @err_count  += 1;
                ensure
                    @exec_count += 1;
                    @exec_time  += Time.now() - t_start
                end
            end

            alias :call :execute!
        end
    end
end