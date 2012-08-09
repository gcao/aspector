# ex:tw=0
# ex:sw=8
#
# $Id: types.rb,v 1.80 2003/11/21 12:16:11 eivind Exp $
#
# Copyright (C) 2002 Eivind Eklund <eivind@FreeBSD.org>
# This code is available under the same license as Ruby.
#
# Module to easily add type checking to methods.
#
# Usage:
# Note that "is" below actually means a kind_of? relation unless
# specifically said to be otherwise.
#
# class MyClass
#	include TypeChecker
#
#	typesig String, String		# Types for next defined method
#	def example1(string1, string2)
#		... do stuff, knowing that string1 and string2 are Strings ...
#	end
#	
#	#
#	# We also support allowing a parameter to have multiple types:
#	#
#	typesig String, [Array, Hash]
#	def example2(string, array_or_hash)
#		... here, we know that string is a String, and array_or_hash
#		is either an Array or a Hash (or a subclass thereof) ...
#	end
#	#
#	# And we can specify that the rest of a parameter list should be of a
#	# single type
#	#
#	typesig Hash, :rest, String
#	def example3(hash, *strings)
#		... Know that hash is a Hash, and strings is an array of
#		Strings ...
#	end
#	#
#	# Sometimes, it is convenient to limit a set of types by what messages
#	# they understand
#	#
#	typesig Type::Respond(:type, :name)
#	def example3(something)
#		print "Something: " + something.name + "\n"
#		if something.type == "Wally"
#			# .. Handle wallies here.
#		end
#	end
#	#
#	# For a limited set of cases, we want to be able to match an EXACT
#	# type.  If we specify with :exact, the next type will be checked with
#	# instance_of? instead of kind_of?
#	#
#	typesig String, :exact, Module
#	def example4(string, module)
#		... Here we know that string is some kind of string,
#		and we know that module is a module, and not a Class ...
#	end
#	#
#	# We also support having something that must match *all* of a
#	# particular set of types - which can be used to test for the
#	# type having mixed in a series of modules, for instance.
#	#
#	# The below looks for subclasses of Array that have been defined
#	# Comparable
#	#
#	typesig Type::And(Array, Comparable)
#	def example5(comparablearray)
#	end
#	#
#	# We support having optional parameters
#	#
#	# XXX :optional is not implemented yet
#	# XXX This screws the arity check over; need code re-org
#	# XXX The example below sucks, anyway.
#	typesig String, String, :optional, String
#	def example6(string1, string2, string3=nil)
#	end
#	#
#	# Also, we can do "argument grouping" - create a
#	# type that "consume" more than one argument, e.g.
#	# for a varargs list that consists of String, Integer
#	# pairs:
#	typesig Class, :rest, Type::Multi(String, Integer)
#	def example7(klass, *pairs)
#		... and pairs[0+2*x] will be a String, while
#		pairs[1+2*x] will be an Integer ...
#	end
#
#	#
#	# Field limitations - where we actually look at the data in the field
#	#
#
#	#
#	# Formatting for a method that takes printf-like arguments, with
#	# the arguments
#	#
#	# XXX Not implemented yet
#	typesig IO, Type::Printf
#	def examplefprintf(file, format, *rest)
#	end
#	#
#	# Limit to strings matching a particular regexp
#	# to_s will be called, so if you want to assure that it IS a string,
#	# you need to do something like
#	# typesig Type::And(String, Type::Regexp(/^\d+/))
#	#
#	typesig Type::Regexp(/something/)
#	#
#	# XXX Document Type::Range
#	# XXX Document Type::Return
#
#	XXX Go through the list of built-in classes for Ruby and see if there
#	are more of them we want to have specific types for restrictions on
#
#	XXX Look at integration with Types.rb from matju
#	XXX Look at abandoning the name Type, as it conflicts with matju
#	XXX Mail matju about the licensing issue, mail address matju@sympatico.ca
#	XXX Tell matju about what technique I'd use to re-implemnt, and talk
#	about how compatible (questions fielded in #ruby-lang after I'd gone
#	home.)
#
#	TODO Make arity work correctly (by overriding Method.arity)
#	TODO Filter exception trace
#	TODO Implement :arity
#	TODO Full normalization of Type::Or (presently only done if entered as
#	[A, B] instead of Type::Or(A, B))
# end
#
#
#
#	If you see any functionality you'd like that is NOT described above,
#	please DO request it.  
#
#
#	XXX Evaluate if we want to be able to add a 'blacklist' for classes
#	that implement <instance>.hash incorrectly.  These will NOT be
#	normalized otherwise.
#

module TypeChecker
	#
	# Avoid the possibility of using this module by extend instead of
	# extend
	#
	def TypeChecker.extend_object(klass)
		raise NotImplementedError, "#{name} is not intended to be extended.  Use 'include #{name}'", caller
	end
	#
	# Set up a class for typechecking if it isn't already
	#
	def TypeChecker.append_features(klass)
		return if klass.respond_to? :typesig
		# XXX The automatic generation of method_added in the class of
		# klass without a fallback is evil.  However, I'm not sure of
		# whether it is worthwhile to be nicer.
		# XXX Besides, it does NOT get called.
		klass.module_eval {
			class <<self
				if method_defined? :method_added
					alias_method :tc_method_added, :method_added
					if instance_methods.include? "method_added"
						remove_method :method_added
					end
				else
					def tc_method_added(unused) end
				end
				def singleton_method_added(method)
					return if Thread.current["TypeChecker::@tc_adding_method"]
					if Thread.current["TypeChecker::@tc_typesig_data"]
						# Avoid problems with self callbacks
						Thread.current["TypeChecker::@tc_adding_method"] = true
						typesig = Thread.current["TypeChecker::@tc_typesig_data"]
						Thread.current["TypeChecker::@tc_typesig_data"] = nil
						TypeChecker.object_set_typesig(self, method, typesig)
						Thread.current["TypeChecker::@tc_adding_method"] = false
					end
				end
			end
		}
		#
		# Add a typesig to a method in a particular class that is extended by
		# TypeChecker.
		#
		def klass.set_typesig(method, *typesig)
			TypeChecker.set_typesig(self, method, Type::Sig(*typesig))
		end

		#
		# Set a typesig for a particular class method.
		# The method must be defined before this is called.
		#
		def klass.set_ctypesig(method, *typesig)
			TypeChecker.object_set_typesig(self, method, Type::Sig(*typesig))
		end
		#
		# Do type checks iff we have registered a set of types for this method
		#
		def klass.method_added(method)
			return if Thread.current["TypeChecker::@tc_adding_method"]
			if Thread.current["TypeChecker::@tc_typesig_data"]
				# Avoid problems with self callbacks
				Thread.current["TypeChecker::@tc_adding_method"] = true
				typesig = Thread.current["TypeChecker::@tc_typesig_data"]
				Thread.current["TypeChecker::@tc_typesig_data"] = nil
				TypeChecker.set_typesig(self, method, typesig)
				Thread.current["TypeChecker::@tc_adding_method"] = false
			end
			tc_method_added(method)
		end
		#
		# Register types for next method
		#
		def klass.typesig(*args)
			raise "typesig called multiple times without method definition between" \
				if Thread.current["TypeChecker::@tc_typesig_data"]
			raise "typesig at inside method_added recursion (this should never happen)" \
				if Thread.current["TypeChecker::@tc_adding_method"]
			Thread.current["TypeChecker::@tc_typesig_data"] = Type::Sig(*args)
		end
	end

	#
	# Add type checks to a live method in a class (do not defer until the object 
	#
	# Note that method_added will be called for the typechecking method being
	# interjected in the call stream (unlike when typesig is used for automatic
	# addition.)
	#
	def TypeChecker.set_typesig(myclass, method, typesig)
		raise ArgumentError, "#{myclass.type.name} does not respond to #{method}" \
			unless myclass.instance_method(method)
		if myclass.class_variables.include? "@@tc_typesig_#{method.__id__}"
			myclass.module_eval "@@tc_typesig_#{method.__id__} = typesig"
		else
			myclass.module_eval <<-eom
				@@tc_typesig_#{method.__id__} = typesig
				alias_method("__tc_#{method.__id__}", method)
				def #{method}(*args)
					# XXX This arity check will not work, but the real call will take care of it
					skip, err = @@tc_typesig_#{method.__id__}.verify(0,
						#{myclass.instance_method(method).arity}, 
						false, args, @@tc_typesig_#{method.__id__})
					if err
						raise ArgumentError, err, caller
					else
						# XXX Filter exception trace
						return __tc_#{method.__id__}(*args)
					end
				end
			eom
		end
	end

	#
	# Add typechecks to a method in a live object.
	#
	# Note that this will result in an anonymous class being
	# created for the object in question, and is thus slightly
	# wasteful.  However, it can be very convenient.
	#
	# For example, when I had a problem that used a Hash, and I wanted to
	# make sure that I only used Strings to index the hash (because I was
	# getting data from several sources and it could arrive to me either
	# as Strings or as Integers), I could have fixed this with
	# TypeChecker.object_set_typesig(myhash, :[], String)
	# TypeChecker.object_set_typesig(myhash, :[]=, String)
	#
	def TypeChecker.object_set_typesig(object, method, *typesig)
		class <<object
			Thread.current["typechecker_object_set_typesig_class"] = self
		end
		if typesig.length == 1 && typesig[0].kind_of?(Type::Sig)
			set_typesig(Thread.current["typechecker_object_set_typesig_class"], method, typesig[0])
		else
			set_typesig(Thread.current["typechecker_object_set_typesig_class"], method, Type::Sig(*typesig))
		end
	end

	#
	# Next argument in typesig
	#
	def TypeChecker.next_arg(args, typeoffset)
		while typeoffset < args.length && args[typeoffset].kind_of?(Symbol)
			typeoffset += 1
		end
		return nil unless typeoffset < args.length
		typeoffset
	end
end


#
# Representation of types, for type checking.
# This can represent arbitarily complex types, not just classes.
# Methods in Type are generally just a short way of creating an object.
#
class Type
	def initialize(*args)
		raise "Type is an abstract class" if self.class == Type
		@args = args
		@verify_message = "is not compatible with #{to_s}"
		Thread.current["Type::@verify_message"] = nil
	end
	#
	# Generate a description of the type as Ruby code
	#
	def inspect
		if @args
			return "#{self.class.name}(" + @args.collect { |arg| arg.inspect }.join(', ') + ")"
		else
			return "#{self.class.name}"
		end
	end

	# XXX It might be more proper to have other code call inspect instead
	# of to_s, but that's more complicated, and YouAintGonnaNeedIt.
	def to_s
		inspect
	end

	#
	# Verify that this particular type is OK for the arg in question.
	#
	# types:: Array of types (with this object somehow available through
	# the slot number given, though that may be through another method)
	# arity:: Method arity for the method called
	# args:: The arguments the method was called with
	# argno:: The argument number to check
	#
	# Returns:
	#	Number of arguments consumed, string for error
	#
	# The default define verify by way of a call to ===.
	# This is useful for most simple types.  A derived type can
	# call set_message() to make verify give a sane message; a description
	# of the argument referenced will be prepended to the message.
	#
	# NOTE: Either ===, verify, or both must be overridden in any child
	# class.
	#
	def verify(argno, arity, exact, args, types)
 		if self.===(args[argno], true)
			return 1, nil
		else
			return nil, "Arg #{argno} " + get_message()
		end
	end

	#
	# Check if this type is compatible with the argument.
	# This allows use of the different types in
	#	case object
	#	when <sometype>
	#		... do stuff ...
	#	end
	#
	# This method may call set_message to set a specific message for
	# how the type failed; see Type::Respond::=== for an example.
	#
	# The default define a === by way of a call to verify.
	# This is useful for composite types like And, Or, Not, and Multi.
	#
	# NOTE: Either ===, verify, or both must be overridden in any child
	# class.
	#
	def ===(other, set_message=false)
		skip, msg = verify(0, -1, false, [other], self)
		return !!skip
	end

	#
	# Set the message for verify.  Intended to be called by
	# === for types that do their checks there, but want to
	# customize the message based on how the object does not match.
	#
	def set_message(msg, set_message=true)
		raise "Bug in Type #{self.class.name}: Varying calls to set_message" \
			if Thread.current["Type::@verify_message"]
		return nil unless set_message
		Thread.current["Type::@verify_message"] = msg
		nil
	end
	private :set_message

	#
	# Get a message previously set by set_message() (or left from object
	# init)
	#
	def get_message
		msg = Thread.current["Type::@verify_message"]
		Thread.current["Type::@verify_message"] = nil
		msg = @verify_message unless msg
		msg
	end
	private :get_message

	#
	# Normalize references to args to be to the first equal arg ever passed
	# (using an internal cache).
	#
	# This assumes that == works for the arguments (as seen from the point
	# of view of typechecking) - ie, that if two objects are matched as ==,
	# either can be used.
	#
	# It also assumes that if arg.hash is implemented, the arg can be
	# placed in a hash.
	#
	# Args will be frozen unless they are modules; if you need an argument
	# to a Type that has varying behaviour based on time (usually a bad
	# idea, but may be useful for certain systems), you need to implement
	# this using an extra layer of indirection.  The use of freeze is intended
	# to avoid obscure application bugs caused by the object aliasing done
	# inside the type handling.
	#
	@@known_arg_types = {}
	def Type.normalize_ref(arg)
		arg.freeze unless arg.kind_of? Module
		argtype = arg.class
		@@known_arg_types[argtype] ||= []
		index = @@known_arg_types[argtype].index(arg)
		if index
			return @@known_arg_types[argtype][index]
		else
			@@known_arg_types[argtype].push(arg)
			return arg
		end
	end

	#
	# Normalize references to args to be the first identical arg ever
	# passed in, to maximize chance of hitting the cache.
	#
	def Type.normalize_arg_refs(args)
		args.collect { |arg| normalize_ref(arg) }
	end

	#
	# For many types, the order of arguments does not matter and number of
	# repeats of an argument does not matter,  and that is all
	# normalization that is possible to do on the type.
	#
	# For those, it is possible to use this normalizer by doing
	# class <<self
	# 	alias_method :normalize_args, :normalize_args_sort
	# end
	#
	def Type.normalize_args_sort_uniq(args)
		normalize_arg_refs(args).sort { |a, b| a.__id__ <=> b.__id__ }.uniq
	end
	#
	# For some types (notably Or and Not), any Or arguments can be flattened in
	# normalization.
	# 
	# XXX This does not normalize Type::Or expressions, just types entered
	# as arrays.
	def Type.normalize_args_sort_uniq_flatten(args)
		normalize_args_sort_uniq(args.flatten)
	end
	#
	# Normalize args to a type.  The default is to just normalize argument
	# references to be to other, equivalent objects, 
	# but this can be overridden in child classes (as done in
	# Type::Respond to use normalize_args_sort).
	#
	class <<self
		alias_method :normalize_args, :normalize_arg_refs
	end

	#
	# Set of objects of this Type, indexed based on arguments.
	# This is used as a cache to get a single copy of a type when
	# it is generated multiple times (e.g, Type::Respond(:to_s, :to_i)
	# at one point in the program will return the exact same object
	# as Type::Respond(:to_i, :to_s) another place in the program.
	# (Arguments are normalized before caching, so the different
	# order of arguments to Type::Respond does not matter.)
	#
	@@type_objs = {}
	#
	# Generate a copy of a type.
	#
	# If an equivalent type has been generated before, this will be retrieved
	# from the object cache instead.
	#
	def Type.create(*args, &block)
		# Normalize args to get a single copy for anything that
		# is equivalent
		args = normalize_ref(normalize_args(args))
		# Generate a hash id for the above - every hash id based on
		# the same set of args will be the same, and every that
		# is different will be different.
		hashid = args.collect { |arg| arg.__id__ }.join('|') + "|" + block.__id__.to_s + "|" + self.__id__.to_s
		unless @@type_objs[hashid]
			# Cache the arguments we got in order to avoid their object
			# ids being reused for different objects at another place in the
			# program.
			# This must be done in order to make sure the hashid
			# above is unique.
			@type_args = args.dup
			# Cache a type object that match the generated type
			@@type_objs[hashid] = new(*args, &block)
		end
		return @@type_objs[hashid]
	end
	# Clients are supposed to use create or Type::<subtype>(args)
	private_class_method :new

	#
	# Make it possible to create types as Type::<type>(args)
	# E.g. Type::Respond(:to_i)
	#
	def Type.method_missing(symbol, *args, &block)
		if symbol.to_s =~ /^[A-Z]/ && const_defined?(symbol) && const_get(symbol).kind_of?(Class)
			begin
				const_get(symbol).create(*args, &block)
			rescue
				raise $!, $!.message, caller
			end
		else
			raise NameError, "undefined method `#{symbol}' for #{name}:#{type}", caller
		end
	end
	#
	# Implement sufficient parts of Array
	#
	def length
		@args.length
	end
	def [](index)
		@args[index]
	end
	def each(&block)
		@args.each(&block)
	end
	def each_index(&block)
		@args.each_index(&block)
	end
	include Enumerable
end

#
# Use of Type for pure namespacing SEPARATED from the actual type stuff.
# This may want to move away
#
class Type
	#
	# Implementation of a simple 'or' type, allowing match of any of the
	# types.
	#
	# The skip will be the SMALLEST of the ones allowed by any of the
	# types in the list, in order to allow more specific typechecking later
	# in the typesig this is part of.
	#
	class Or < self
		def initialize(*args)
			args.each_index { |argno|
				arg = args[argno]
				if arg.kind_of? Type
				elsif arg.kind_of? Module
				else
					raise ArgumentError,
"Arg #{argno} to #{type.name} is invalid (expected [Module, Type], got #{arg.type.name}"
				end
			}
			super
		end
		class << self
			alias_method :normalize_args, :normalize_args_sort_uniq_flatten
		end
		def verify(argno, arity, exact, args, *typesig)
			minskip = nil
			@args.each { |arg|
				if arg.kind_of?(Type)
					offset, string = arg.verify(argno, arity, exact, args, *typesig)
					next if string
					minskip = offset if !minskip || minskip > offset
					break if minskip == 1
				elsif arg.kind_of?(Module)
					if ((!exact && args[argno].kind_of?(arg)) ||
					    (exact && args[argno].instance_of?(arg)))
						minskip = 1
						break
					end
				else
					raise ArgumentError, "Inccorect type to #{inspect}"
				end
			}
			if minskip
				return minskip, nil
			else
				return nil, \
"Arg #{argno} is of invalid type (expected " + (exact ? "exact " : "") + \
	"match in [#{@args.join(', ')}], got #{args[argno].class.name} (#{args[argno].inspect}))"
			end
		end
	end
	
	#
	# Type that verifies an entire typesig.
	#
	class Sig < self
		#
		# Check and normalize a typesig before use.
		#
		# This verifies that all convetions are OK, so a set of types can
		# be shown as faulty at initial definition instead of first use.
		#
		def self.normalize_args(args)
			args = Type.normalize_arg_refs(args)
			args.each_index { |typeoffset|
				mytype = args[typeoffset]
				if mytype.kind_of? Module
				elsif mytype.kind_of? Array
					args[typeoffset] = Type::Or(*mytype)
				elsif mytype.kind_of? Type
				elsif mytype.kind_of? Symbol
					raise ArgumentError, "#{mytype.inspect} without next parameter", caller(3) \
						if typeoffset+1 == args.length
					case mytype
					when :rest
						next_type = TypeChecker.next_arg(args, typeoffset)
						raise ArgumentError, "No type after :rest" unless next_type
						raise ArgumentError, "More than one parameter after :rest", caller(3) \
							unless next_type+1 >= args.length
					when :exact
					else
						raise ArgumentError, "Unknown modifier: #{mytype.inspect}", caller
					end
				else
					raise "Invalid typesig"
				end
			}
			args
		end

		#
		# Verify that an argument list match a typesig
		#
		def verify(argno, arity, exact, args, typesig)
			if arity >= 0
				return nil, "wrong # of arguments (#{args.length} for #{arity})" \
					unless args.length == arity
			else
				return nil, "wrong # of arguments (#{args.length} for #{-arity - 1})" \
					unless args.length >= -arity-1
			end
			argoffset = 0
			typeoffset = 0
			argslength = args.length
			typesiglength = typesig.length
			ok = false		# Pre-initialization for Array tests; speed issue
			rest = false		# Are we processing a :rest clause?
			exact = false		# Should next argument be exact?
			while argoffset < argslength && typeoffset < typesiglength
				mytype = typesig[typeoffset]
				if mytype.kind_of? Type
					offset, string = mytype.verify(argoffset, arity, exact, args, typesig)
					return nil, string if string
					argoffset += offset
				elsif mytype.kind_of? Symbol
					case mytype
					when :rest
						rest = true
						typeoffset += 1
					when :exact
						exact = 1
						typeoffset += 1 if rest
					else
						raise ArgumentError, "Unknown modifier in Type::Sig.verify"
					end
				else
					raise "Got #{mytype.type.name} (#{mytype.inspect}) instead of Module" unless mytype.kind_of? Module
					if ((!exact && args[argoffset].kind_of?(mytype)) ||
				    	(exact  && args[argoffset].instance_of?(mytype)))
						argoffset += 1
					else
						return nil, \
"Arg #{argoffset} is of invalid type (expected #{mytype}, got #{args[argoffset].type})"
					end
				end
				unless rest
					typeoffset += 1
					exact = false if exact == 0
					exact = 0 if exact == 1
				end
			end
			return 1, nil
		end
		#
		# === work on an array of arguments.
		#
		def ===(other, set_message=false)
			skip, message = verify(0, other.length, false, other, self)
			return !message
		end
	end
	#
	# Type verifier for types defined exclusively by what messages they respond_to.
	#
	class Respond < self; include TypeChecker
		class << self
			alias_method :normalize_args, :normalize_args_sort_uniq
		end
		set_typesig :initialize, :rest, Symbol
		def ===(other, set_message=false)
			@args.each { |symbol|
				unless other.respond_to? symbol
					set_message("does not respond to #{symbol}") if set_message
					return false
				end
			}
			return true
		end
	end
	#
	# Make a new type that use the passed block to check.
	#
	# Usage:
	#	Type::Make("Isn't numeric string") { |arg| arg =~ /^\d+$/ }
	#
	# Note:
	#	Using a block to check something is quite a bit less efficent
	#	than using the built-in types, as the built-in types takes
	#	special care to only create one instance per unique type, 
	#	are written with efficiency in mind, and require one less call-level.
	#	XXX The following is not implemented yet
	#	Also, built-in types can be compiled to code that runs as part of the
	#	actual ruby call generated to check types, instead of running through
	#	the Type interface.
	class Make < self
		def initialize(message, &block)
			raise ArgumentError, "Missing block to #{type.name}", caller \
				unless block_given?
			@message = message
			@block = block
			super
		end
		def ===(other, set_message=false)
			@block.call(other) || set_message(@message, set_message)
		end
	end

	#
	# Implementation of a simple 'and' type, allowing match of
	# all of a set of types.
	#
	class And < self
		class << self
			# XXX Should always sort Modules before Types
			alias_method :normalize_args, :normalize_args_sort_uniq
		end
		def verify(argno, arity, exact, args, *typesig)
			minskip = nil
			@args.each { |arg|
				failed = false
				if arg.kind_of?(Type)
					offset, string = arg.verify(argno, arity, exact, args, *typesig)
					failed = true if string
					minskip = offset if !minskip || minskip > offset
				elsif arg.kind_of?(Module)
					if ((!exact && args[argno].kind_of?(arg)) ||
					    (exact && args[argno].instance_of?(arg)))
						minskip = 1
					else
						failed = true
					end
				else
					raise ArgumentError, "Inccorect type to #{inspect}"
				end
				break if failed && minskip == 1
			}
			if minskip && !failed
				return minskip, nil
			else
				return nil, \
"Arg #{argno} is of invalid type (expected " + (exact ? "exact " : "") + "match with [#{@args.join(', ')}], got #{args[argno].type})"
			end
		end
	end
	#
	# Type that verifies N other, ordered types in a typesig.
	#
	class Multi < self; include TypeChecker
		# XXX Some way to check that initialize get at least two args?
		# E.g. set_typesig, :initialize, :arity , -2-1, :rest, [Type, Module]
		# The present verification is not good enough, so we need to introduce an
		# extra temporary method below.
		typesig :rest, [Type, Module]
		def initialize(*args)
			raise ArgumentError, "Too few parameters to Type::Multi" \
				unless args.length >= 2
			super
		end
		def verify(argno, arity, exact, args, *typesig)
			skip = nil
			@args.each_index { |i|
				if @args[i].kind_of? Type
					skip, message = @args[i].verify(argno + i, arity, exact, args, *typesig)
					return nil, "Arg #{argno} to Arg #{argno+@args.length - 1}: " + message if message
				elsif @args[i].kind_of? Module
					return nil, "Arg #{argno+i} has invalid type (expected " + (exact ? "exactly " : "")  + "#{@args[i].name}, got #{args[argno+i].type.name}" \
						unless (!exact && args[argno+i].kind_of?(@args[i])) ||
							(exact && args[argno+i].instance_of?(@args[i]))
					skip = 1
				else
					# Should never happen - typesig in the
					# class should take care of it at init
					# time.
					raise ArgumentError, "Incorrectly set up #{name}"
				end
			}
			return @args.length - 1 + skip, nil
		end
	end
	#
	# Verify that a parameter set do not match a set of types.
	#
	class Not < self
		class << self
			alias_method :normalize_args, :normalize_args_sort_uniq_flatten
		end
		def verify(argno, arity, exact, args, *typesig)
			minskip = nil
			@args.each { |arg|
				failed = false
				if arg.kind_of?(Type)
					offset, string = arg.verify(argno, arity, exact, args, *typesig)
					failed = true if !string
					minskip = offset if !minskip || minskip > offset
				elsif arg.kind_of?(Module)
					if ((!exact && args[argno].kind_of?(arg)) ||
					    (exact && args[argno].instance_of?(arg)))
						failed = true
					else
						minskip = 1
					end
				else
					raise ArgumentError, "Inccorect type to #{inspect}"
				end
				break if failed && minskip == 1
			}
			if minskip && !failed
				return minskip, nil
			else
				return nil, \
"Arg #{argno} is of invalid type (expected " + (exact ? "exact " : "") + "match with [#{@args.join(', ')}], got #{args[argno].type})"
			end
		end
	end
	#
	# Verify that object is inside an argument range
	#
	class Range < self; include TypeChecker
		# XXX The use of an actual initialize method here should not be necessary;
		# this needs :arity, and some way of specifying the > relation inside the
		# typelist (assuming we don't want to support "except"-ranges; relaxing
		# this restriction might actually be useful.)
		# Typesig for that case:
		# set_typesig :initialize, :arity, 2, Type::And(Type::Not Type::Multi(NilClass, NilClass), [NilClass, Type::Respond :>]), [NilClass, Type::Respond :<]
		# (NOTE: No check of greater-than relation)
		typesig [NilClass, Type::Respond(:>)], [NilClass, Type::Respond(:<)]
		def initialize(min, max)
			raise ArgumentError, "max (#{max.inspect}) < min (#{min.inspect})" if max && min && max < min
			raise ArgumentError, "min (#{max.inspect}) > max (#{max.inspect}) (and the compare is inconsistent)" if max && min && min > max
			raise ArgumentError, "double nil" if !min && !max
			super
		end
		def ===(other, set_message=false)
			return set_message("is smaller than #{@args[0]}", set_message) if @args[0] && @args[0] > other
			return set_message("is larger than #{@args[1]}", set_message) if @args[1] && @args[1] < other
			true
		end
		
	end

	#
	# Check return value from one of the methods in the argument
	#
	class Return < self
		# XXX Should be able to check that initialize set the right number of args
		#set_typesig :initialize, :arity, 2, Symbol, [Type, Module]
		def ===(other, set_message=false)
			return @args[1] === other.send(@args[0])
		end
	end

	#
	# Check that an argument is not nil.
	#
	# Use NilClass to check for an argument of nil.
	#
	class NotNil < self
		# XXX Make :arity work
		#set_typesig :initialize, :arity, 0
		def ===(other, set_message=false)
			other || set_message("is nil", set_message)
		end
	end

	#
	# Check that the argument match (=~) one or more of a series of
	# regexps.
	#
	# XXX WARNING: The interface to this may CHANGE.
	#
	# XXX This should use === and be called "Match".
	# XXX Message should include description
	class Regexp < self; include TypeChecker
		set_typesig :initialize, :rest, Type::Respond(:=~)
		def ===(other, set_message=false)
			@args.each { |regexp|
				return true if other =~ regexp
			}
			#set_message("(#{other.inspect}) is not compatible with #{@args.collect { |a| a.inspect }.join(", ")}", set_message)
			false
		end
	end
	
	#
	# Check that an argument has a series of hashkeys with specified types.
	#
	#
	# WARNING: The interface to this MAY CHANGE.
	#
	#
	# XXX Should not need to use verify, as exact should be passed to ===
	#
	# XXX Should take an optional second parameter to initialize,
	# specifying types that identify what constraints there are on the keys
	# in the hash, apart from the constraints for specific values.
	#
	# XXX There should probably also be a constraint for the values
	# themselves - perhaps if the first argument is a type instead of a
	# hash, it counts as a value constraint?
	#
	# XXX Not implemented yet:
	# Calling convention:
	#  Type::Hash(Hash)
	#	Check that each key passed in exists; if it points at a
	#	Type/Module, check that the value corresponding to that key
	#	in the data passed in match the type provided.
	# 
	#  Type::Hash(Type)
	#	Check that each key correspond to the Type passed in
	#
	#  Type::Hash(Hash, Type)
	#	Same as Type::Hash(Hash), but also verify that each value correspond to the Type,
	#	unless it is listed in Hash
	#
	#  Type::Hash(Type, Type)
	#	Check key type and value type
	#
	#  Type::Hash(Hash, Type, Type)
	#	Check as Type::Hash(Hash), plus values, plus check type of keys
	#	not in hash
	#
	# XXX I should list out all the different cases, and test that they are
	# handled.
	# XXX "element" => [Type, Type] does not work (should become "element" => Type::Or(Type, Type))
	# XXX There is no way to place the restriction "Some of these fields,
	# with the matching types if they are there" - ie, optional fields.
	class Hash < self; include TypeChecker
		typesig ::Hash
		def initialize(hash)
			hash.each { |key, value|
				raise ArgumentError, "hash[#{key}] neither Module nor Type", caller \
					unless value.kind_of?(Module) or value.kind_of?(Type)
			}
			super
		end
		def verify(argno, arity, exact, args, typesig)
			# XXX Do we want to do skip tracking for hashes?
			smallskip = nil
			#return nil, "Arg #{argno} is not hash type" unless args[argno].kind_of? Hash
			return nil, "Arg #{argno} is not hash type" unless args[argno]
			@args[0].each { |key, value|
				return nil, "Arg #{argno} miss key #{key.inspect}" \
					unless args[argno].has_key? key
				if value.kind_of? Module
					return nil,
"Arg #{argno} key #{key} (a #{value.class.name}) does not " + (exact ? "exactly " : "") + "match #{value.inspect}" \
						unless (!exact && args[argno][key].kind_of?(value)) ||
							(exact && args[argno][key].instance_of?(value))
				else
					skip, msg = value.verify(0, 1, exact, [args[argno][key]], typesig)
					if msg
						return nil, "Arg #{argno} key #{key} " + msg
					end
					smallskip = skip if !smallskip || skip < smallskip
				end
			}
			if smallskip
				return smallskip, nil
			else
				return 1, nil
			end
		end
	end

	#
	# Check that an argument match a particular object
	#
	class Equals < self
		def ===(other, set_message = false)
			@args[0] == other ||
				set_message("is not equal to #{@args[0].inspect}", set_message)
		end
	end
	#
	# Set explict skip from other verifier
	#
	class Skip < self
		# XXX Should allow exactly two parameters
		def verify(argno, arity, exact, args, typesig)
			# XXX Lacks implementation
		end
	end

	#
	# Type that always fails; e.g. useful for disallowing unknown keys in
	# hashes.
	#
	class False < self
		def ===(other, set_message=false)
			false
		end
	end

	#
	# Type that always passes; mostly for symmetry with Type::False
	#
	class True < self
		def ===(other, set_message=false)
			true
		end
	end

	#
	# Type for True/False
	#
	# XXX Lacks tests
	class Boolean < self
		def ===(other, set_message=false)
			other.kind_of?(TrueClass) || other.kind_of?(FalseClass) ||
				set_message("is neither 'true' nor 'false'", set_message)
		end
	end

	#
	# Type for checking that something is a subtype of one or more Modules
	#
	# XXX Better name and less restrictions?
	#class Module < self
	#	#set_typesig :initialize, :rest, Module
	#	def ===(other, set_message=false)
	#		@args.each { |module|
	#			return set_message("is not a kind of #{module.name}", set_message) unless other.kind_of? module
	#		}
	#	end
	#end
	#
	# Type for verifying exact membership in a class
	#
	#class EModule < self
	#	# XXX Should set arity
	#	#set_typesig :initialize, :rest, Class
	#	def ===(other, set_message=false)
	#		@args.each { |module|
	#			return set_message("is not an instance of #{module.name}", set_message) unless other.instance_of? @args[0]
	#		}
	#	end
	#end
end
