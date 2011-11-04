# More info at https://github.com/guard/guard#readme

guard 'bundler' do
  watch('Gemfile')
end

#guard 'shell' do
#  watch(%r{^(lib|spec)/.+\.rb$}) { `rspec spec` }
#end

guard 'rspec', :notification => false do
  watch(%r{^(lib|spec)/.+\.rb$}) { "spec" }
end
