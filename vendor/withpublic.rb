module WithPublic
	#
	# Temporary make method available.
	# This will manipulate klass so symbol is public, yield, and restore symbol the
	# way it was.
	#
	def with_public(symbol)
		public_class_method symbol
		begin
			yield
		ensure
			private_class_method symbol
		end
		return

		# XXX The following does not work, but is a skeleton for
		# making the code handle protected etc correctly.
		if private_instance_methods.include? symbol
			# It's private - shuffle back and forth
			public_class_method symbol
			begin
				yield
			ensure
				private_class_method symbol
			end
		elsif protected_instance_methods.include? symbol
			# It's protected - shuffle it back and forth, and also shuffle
			# around access control methods so I can do that.
			public_class_method symbol
			begin
				yield
			ensure
				if private_instance_methods.include? :protected
					public_class_method :protected
					protected symbol
					private_class_method :protected
				elsif klass.protected_instance_methods.include? :protected
					public_class_method :protected
					protected symbol
					protected :protected
				else
					protected symbol
				end
			end
		else
			# It's public - we do not need to do anything
			yield
		end
	end
end


