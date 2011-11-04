# More info at https://github.com/guard/guard#readme

guard 'bundler' do
  watch('Gemfile')
end

#guard 'shell' do
#  watch(%r{^(lib|spec)/.+\.rb$}) { `rspec spec 2>&1` }
#end

guard 'rspec', :notification => false do
  watch(%r{^spec/.+_spec\.rb$})
  watch(%r{^lib/(.+)\.rb$})     { |m| "spec/lib/#{m[1]}_spec.rb" }
  watch('spec/spec_helper.rb')  { "spec" }
end
