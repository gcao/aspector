# We ignore this because this module contains a method template and it won't be shorter
# rubocop:disable ModuleLength

module Aspector
  # ERB template that will be used to define the new version of method to which we will bind
  # with the aspect interception.
  # @note We use it with class_eval and method definitions instead of prepend because of
  #   performance reasons
  # @note Keep in mind that lines that start with % are evaluated in the interception context
  module MethodTemplate
    # ERB template for method recreation
    TEMPLATE = ERB.new <<-CODE, nil, '%<>'
%     if around_advice
        wrapped_method = instance_method(:<%= method %>)
%     end

      define_method :<%= method %> do |*args, &block|
%       if logger.debug?
          logger.debug '<%= method %>', 'enter-generated-method'
%       end

        unless aspect.enabled?
%         if logger.debug?
            logger.debug '<%= method %>', 'exit--generated-method'
%         end

          return orig_method.bind(self).call(*args, &block)
        end

%       before_advices.each do |advice|
%         if logger.debug?
            logger.debug '<%= method %>', 'before-invoke-advice', '<%= advice.name %>'
%         end

%         if advice.advice_code
            result = (<%= advice.advice_code %>)
%         else
            result = <%= advice.with_method %> <%
              if advice.options[:interception_arg] %>interception, <% end %><%
              if advice.options[:method_arg] %>'<%= method %>', <% end
              %>*args
%         end

%         if logger.debug?
            logger.debug '<%= method %>', 'after--invoke-advice', '<%= advice.name %>'
%         end

%         if advice.before_filter?
            unless result
%             if logger.debug?
                logger.debug '<%= method %>', 'exit-due-to-before-filter', '<%= advice.name %>'
%             end

              return
            end
%         end
%       end

%       if around_advice
%         if logger.debug?
            logger.debug '<%= method %>', 'before-invoke-advice', '<%= around_advice.name %>'
%         end

%         if around_advice.advice_code
            result = (
              <%=
                around_advice
                  .advice_code
                  .gsub(
                    'INVOKE_PROXY',
                    'wrapped_method.bind(self).call(*args, &block)'
                  )
              %>
            )
%         else
%           if logger.debug?
              proxy = lambda do |*args, &block|
                logger.debug '<%= method %>', 'before-invoke-proxy'
                res = wrapped_method.bind(self).call *args, &block
                logger.debug '<%= method %>', 'after--invoke-proxy'
                res
              end
              result = <%= around_advice.with_method %> <%
                if around_advice.options[:interception_arg] %>interception, <% end %><%
                if around_advice.options[:method_arg] %>'<%= method %>', <% end
                %>proxy, *args, &block
%           else
              result = <%= around_advice.with_method %> <%
                if around_advice.options[:interception_arg] %>interception, <% end %><%
                if around_advice.options[:method_arg] %>'<%= method %>', <% end
                %>wrapped_method.bind(self), *args, &block
%           end
%         end

%         if logger.debug?
            logger.debug '<%= method %>', 'after--invoke-advice', '<%= around_advice.name %>'
%         end
%       else
          # Invoke original method
%         if logger.debug?
            logger.debug '<%= method %>', 'before-wrapped-method'
%         end

          result = orig_method.bind(self).call *args, &block
%         if logger.debug?
            logger.debug '<%= method %>', 'after--wrapped-method'
%         end
%       end

%       unless after_advices.empty?
%         after_advices.each do |advice|
%           if logger.debug?
              logger.debug '<%= method %>', 'before-invoke-advice', '<%= advice.name %>'
%           end

%           if advice.advice_code
              result = (<%= advice.advice_code %>)
%           else
%             if advice.options[:result_arg]
                result = <%= advice.with_method %> <%
                  if advice.options[:interception_arg] %>interception, <% end %><%
                  if advice.options[:method_arg] %>'<%= method %>', <% end %><%
                  if advice.options[:result_arg] %>result, <% end
                  %>*args
%             else
                <%= advice.with_method %> <%
                  if advice.options[:interception_arg] %>interception, <% end %><%
                  if advice.options[:method_arg] %>'<%= method %>', <% end
                  %>*args
%             end
%           end

%           if logger.debug?
              logger.debug '<%= method %>', 'after--invoke-advice', '<%= advice.name %>'
%           end
%         end
%       end

%       if logger.debug?
          logger.debug '<%= method %>', 'exit--generated-method'
%       end

        result
      end
    CODE
  end
end
