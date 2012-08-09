#!/usr/local/bin/ruby -w
# ex:tw=0
# vim:sw=4
# vim:sts=4
#
# Copyright (C) 2002 Eivind Eklund.
# All rights reserved.
# Available under the same license as Ruby.
#

require 'test/unit'
require './types'

module Test
    module Unit
    	class TestCase
	    #
	    # Verify that the code raise an exception of the correct type, with
	    # a message that match string (which can also be a regexp.)
	    #
	    # XXX We should also have a variant that checks that the backtrace
	    # starts from the block passed to assert_raises_msg; this may not
	    # be possible with the present level of Ruby introspection, though
	    # (no way to get the end line of the block).
	    # COULD check that we are being called from the correct file, and
	    # optionally that this is below the present calling point, and/or within N lines of here.
	    # Could be done either by having the user pass in file/line ranges, or by having the user
	    # pass in the number of lines after the assertion to match.
	    def assert_raises_msg(expected_exception_klass, string, message)
		_wrap_assertion {
		    assert_instance_of(Class, expected_exception_klass, "Should expect a type of exception")
		    actual_exception = nil
		    full_message = build_message(message, expected_exception_klass) {
			| arg |
			"Expected exception of type <#{arg}> but none was thrown"
		    }
		    assert_block(full_message) {
			thrown = false
			begin
			    yield
			rescue Exception => thrown_exception
			    actual_exception = thrown_exception
			    thrown = true
			end
			thrown
		    }
		    full_message = build_message(message, expected_exception_klass, actual_exception.class.name, 
						actual_exception.message,
						actual_exception.backtrace.join("\n\t")) {
			|arg1, arg2, arg3, arg4|
			"Expected exception to be of type <#{arg1}> but was <#{arg2}: #{arg3}\n\t#{arg4}>"
		    }
		    assert_block(full_message) {
			expected_exception_klass == actual_exception.class
		    }
		    full_message = build_message(message, string, actual_exception.message,
						actual_exception.backtrace.join("\n\t")) {
			|arg1, arg2, arg3|
			"Expected message to match \"#{arg1}\" but was \"#{arg2}\"\n\t#{arg3}>"
		    }
		    assert_block(full_message) {
			if string.kind_of?(String)
			    string == actual_exception.message
			else
			    string =~ actual_exception.message
			end
		    }
		    actual_exception
		}
	    end
	end
    end
end

class TCMock
	# Help for verifying that we do get the calls we want
	@@method_added_called = false
	def TCMock.method_added(unused)
		@@method_added_called = true
	end
	def TCMock.method_added_called
		@@method_added_called
	end
	def TCMock.method_added_called=(value)
		@@method_added_called = value
	end
end

class TypeCheckerTest < Test::Unit::TestCase
	attr_accessor :tc
	def set_up
		#
		# Set up basic anonymous class for testing.
		#
		@tc = Class.new
		assert_nothing_raised("Exception during tc.include") {
			@tc.instance_eval { include TypeChecker }
		}
		$stdout.sync = true
	end
	alias_method :setup, :set_up

	#
	# Test if method_added adds the methods it should
	#
	def test_method_added
		assert_raises_msg(NotImplementedError,
			"TypeChecker is not intended to be extended.  Use 'include TypeChecker'",
			"'extend' of TypeChecker should not be allowed") {
			TCMock.extend TypeChecker
		}
		assert(TCMock.method_added_called == false,
			"TCMock.method_added_called true at start")
		assert_nothing_raised("Exception during TCMock.include") {
			TCMock.instance_eval { include TypeChecker }
		}
		TCMock.method_added_called = false
		assert_nothing_raised("Adding typesig for TCMock.nothing") {
			TCMock.typesig()
		}
		assert_nothing_raised("Exception during adding of trivial method to TCMock") {
			TCMock.module_eval "def nothing;end"
		}
		assert(TCMock.method_added_called == true,
			"TCMock.method_added_called not set after new method define")
	end
	def test_multi_arg
		#
		# Prepare a simple method with no args
		#
		assert_nothing_raised("Adding typesig for tc.nothing") {
			@tc.typesig()
		}
		assert_nothing_raised("Exception during adding of trivial method to tc") {
			@tc.module_eval "def nothing;end"
		}
		#
		# Prepare a multiarg method for use, with typesig
		#
		assert_nothing_raised("Adding typesig for multiarg method") {
			@tc.typesig(Integer, Integer)
		}
		assert_nothing_raised("Adding multiarg method w/types") {
			@tc.module_eval "def twoplus(a, b, *rest);end"
		}
		assert_nothing_raised("Adding multiarg method w/o types") {
			@tc.module_eval "def two(a, b); end"
		}

		#
		# Start making objects and testing them
		#
		testobj = nil
		assert_nothing_raised("Unable to create trivial test object") {
			testobj = @tc.new
		}
		assert_nothing_raised("Cannot correctly call 'nothing'") {
			testobj.nothing
		}
		assert_raises_msg(ArgumentError,
			"wrong # of arguments (1 for 0)",
			"Missing check of number of parameters") {
			testobj.nothing(1)
		}
		assert_raises_msg(ArgumentError, "wrong # of arguments (1 for 2)", "Accepts too few args (varargs)") {
			testobj.twoplus(1)
		}
		assert_nothing_raised(ArgumentError, "Exact argument number limit") {
			testobj.twoplus(1, 2)
		}
		assert_nothing_raised(ArgumentError, "Exploiting varargs") {
			testobj.twoplus(1, 2, 3)
		}
		assert_raises_msg(ArgumentError, 
			"Arg 1 is of invalid type (expected Integer, got String)",
			"String to twoplus") {
			testobj.twoplus(1, "This will fail")
		}
		# Verify that we do not have carry-over to the next method
		assert_nothing_raised("two does not accept Strings?!?") {
			testobj.two("String 1", "String 2")
		}
	end
	#
	# Test of the ability for a single arg to pass multiple
	#
	def test_multi_typed_arg
		#
		# Now, for some methods that have more complex signatures,
		# specifically the possibility of passing different types
		# in a single parameter
		#
		assert_nothing_raised("Set up multi-type argument") {
			@tc.typesig(String, [Array, Hash], Integer)
		}
		assert_nothing_raised("Set up method for multi-type argument") {
			@tc.module_eval "def three(a, b, c); end"
		}
		testobj = nil
		assert_nothing_raised("Creating of 2nd @tc object") {
			testobj = @tc.new
		}
		assert_nothing_raised("Execution of three with OK parameters (Array)") {
			testobj.three("A", [], 1)
		}
		assert_nothing_raised("Execution of three with other OK parameters (Hash)") {
			testobj.three("B", {}, 1)
		}
		assert_raises_msg(ArgumentError,
			"Arg 0 is of invalid type (expected String, got Fixnum)",
			"Other parameters than allowed, multi-type (arg 1, non-multi)") {
			testobj.three(1, "C", 1)
		}
		assert_raises_msg(ArgumentError, 
			"Arg 1 is of invalid type (expected match in [Hash, Array], got String (\"C\"))",
			"Other parameters than allowed, multi-type (arg 2, multi)") {
			testobj.three("B", "C", 1)
		}
	end
	#
	# Test of the :rest operator
	#
	def test_operator_rest
		testobj = nil
		assert_nothing_raised("Adding resttester") {
			@tc.typesig String, :rest, Integer
			@tc.module_eval "def multi(a, *rest); end"
			testobj = @tc.new
		}
		assert_nothing_raised("Call to multi with no arguments for rest") {
			testobj.multi("string")
		}
		assert_nothing_raised("Call to multi with arguments for multiple rest") {
			testobj.multi("string", 1, 2)
		}
		assert_raises_msg(ArgumentError,
			"Arg 2 is of invalid type (expected Integer, got String)",
			"Call to multi with wrong arguments for rest") {
			testobj.multi("string", 1, "string2")
		}
		assert_raises_msg(ArgumentError,
			":rest without next parameter",
			"Adding incorrect typesig (:rest at end)") { 
			@tc.typesig(String, :rest)
		}
		assert_raises_msg(ArgumentError,
			"More than one parameter after :rest",
			"Adding incorrect typesig (:rest with more than one parameter)") { 
			@tc.typesig(String, :rest, Integer, Integer)
		}
	end
	#
	# Test of Type::Respond
	# This will also test that it work correctly inside arrays,
	# effectively giving a test for Type inside arrays.
	#
	def test_type_response
		testobj = nil
		assert_nothing_raised("Setting up Type::Respond(:to_i)") {
			@tc.typesig Type::Respond(:to_i)
			@tc.module_eval "def respond_to_i(i); end"
			# Since this is the first type we've added 
			@tc.typesig [Type::Respond(:to_i), Hash]
			@tc.module_eval "def respond_to_i_array(i); end"
			testobj = @tc.new
		}
		assert_nothing_raised("OK data send to Type::Respond(:to_i)") {
			testobj.respond_to_i(1)
			testobj.respond_to_i(:name)
		}
		assert_raises_msg(ArgumentError,
			"Arg 0 does not respond to to_i",
			"Bad data send to Type::Respond(:to_i)") {
			testobj.respond_to_i([])
		}
		assert_nothing_raised("OK data send to Type::Respond_array(:to_i)") {
			testobj.respond_to_i_array(1)
			testobj.respond_to_i_array(:name)
		}
		assert_raises_msg(ArgumentError,
			/Arg 0 is of invalid type \(expected match in \[(Hash, Type::Respond\(:to_i\)|Type::Respond\(:to_i\), Hash)\], got Array \(\[\]\)\)/,
			"Bad data send to Type::Respond_array(:to_i)") {
			testobj.respond_to_i_array([])
		}
		assert_nothing_raised("Hash pass to respond_to_i_array") {
			testobj.respond_to_i_array({})
		}
		assert(Type::Respond(:to_i, :to_s) == Type::Respond(:to_s, :to_i), 
			"Type::Respond does correct collapsing of multiple equivalent instances")
		assert(Type::Respond(:to_i, :to_s, :to_i) == Type::Respond(:to_s, :to_i, :to_s), 
			"Type::Respond does correct collapsing of multiple equivalent instances with repeated args")
	end
	#
	# Test that the ':exact' specifier work as it should.
	#
	def test_typesig_exact
		assert_nothing_raised(":exact on simple class") {
			@tc.typesig :exact, Module, Module
			@tc.module_eval "def tmodule(mod, string); end"
		}
		assert_nothing_raised(":exact on array set with module") {
			@tc.typesig :exact, [Module, String], Module
			@tc.module_eval "def tmodule_string(module_or_string, mod); end"
		}
		tmpobj = nil
		assert_nothing_raised("object creation for :exact test object") {
			tmpobj = @tc.new
		}
		assert_nothing_raised(":exact not forced for next parameter") {
			tmpobj.tmodule(Comparable, Object)
		}
		assert_raises_msg(ArgumentError,
			"Arg 0 is of invalid type (expected Module, got Class)",
			":exact limits simple module") {
			tmpobj.tmodule(Object, Object)
		}
		assert_raises_msg(ArgumentError,
			"Arg 0 is of invalid type (expected exact match in [String, Module], got Class (Object))",
			":exact limits in array set") {
			tmpobj.tmodule_string(Object, Object)
		}
		assert_nothing_raised(":exact passes primary type in array set") {
			tmpobj.tmodule_string(Comparable, Object)
		}
		assert_nothing_raised(":exact not blocking other types in array set") {
			tmpobj.tmodule_string("test", Object)
		}
	end

	#
	# Test interaction between the :rest and :exact options
	#
	def test_exact_rest_interaction
		testobj = nil
		assert_raises(ArgumentError, ":exact, :rest <terminated>") {
			@tc.typesig :exact, :rest
		}
		assert_raises(ArgumentError, ":rest, :exact <terminated>") {
			@tc.typesig :rest, :exact
		}
		assert_nothing_raised(":exact, :rest, Object") {
			@tc.typesig :exact, :rest, Object
			@tc.module_eval "def object(*objs); end"
			testobj = @tc.new
			testobj.object(Object.new)
			testobj.object(Object.new, Object.new)
		}
		assert_raises(ArgumentError, ":exact, :rest, Object (non-Object)") {
			testobj.object(Class.new)
		}
		assert_raises(ArgumentError, ":exact, :rest, Object (Object, non-Object)") {
			testobj.object(Object.new, Class.new)
		}
		assert_nothing_raised(":rest, :exact, Object") {
			@tc.typesig :rest, :exact, Object
			@tc.module_eval "def object2(*objs); end"
			testobj = @tc.new
			testobj.object2(Object.new)
			testobj.object2(Object.new, Object.new)
		}
		assert_raises(ArgumentError, ":rest, :exact, Object (non-Object)") {
			testobj.object2(Class.new)
		}
		assert_raises(ArgumentError, ":rest, :exact, Object (Object, non-Object)") {
			testobj.object2(Object.new, Class.new)
		}
	end

	#
	# Test implementation of object_set_typesig
	# 
	def test_object_set_typesig
		myhash = {}
		assert_nothing_raised("Simple setup of object_set_typesig String check on hash") {
			TypeChecker.object_set_typesig(myhash, :[], String)
			# XXX Do we want just String to work here?  Present
			# implementation separates test of arity and typeset
			TypeChecker.object_set_typesig(myhash, :[]=, String, Object)
		}
		assert_nothing_raised("Access of hash with correct key type") {
			assert(myhash["test"] == nil, "Non-nil return from unknown key in hash with typesig")
		}
		assert_nothing_raised("Setting hash with correct key type") {
			myhash["test"] = 1
		}
		assert_nothing_raised("Accessing hash with correct key type (initialized)") {
			assert(myhash["test"] == 1, "Wrong value in hash after initialization")
		}
		assert_raises(ArgumentError, "Setting hash using wrong key type") {
			myhash[1] = 2
		}
		assert_raises(ArgumentError, "Accessing hash using wrong key type") {
			tmp = myhash[1]
		}
	end
	#
	# Test that the locking code for descriptions of type errors
	#
	def test_verify_lock
		type = nil
		assert_nothing_raised("Defining types for verify thread test") {
			typeclass = Class.new(Type)
			typeclass.module_eval <<-eom
				def ===(other, set_message=false)
					set_message(other) if set_message
					sleep(1) if other == "sleep"
					false
				end
			eom
			# Unique parameters to work around that we are an instance of Type,
			# but have different behaviour, and Type.create caches.
			type = typeclass.create("test_verify_lock create")
		}
		thread_was_run = false
		main_was_run = false
		old_abort = Thread.abort_on_exception
		Thread.abort_on_exception = true
		thread = Thread.new {
			assert_nothing_raised("Running simple verification in thread") {
				skip, message = type.verify(0, 1, false, ["sleep"], type)
				assert(skip == nil, "Bug in test_verify_lock test class (thread)")
				assert(message == "Arg 0 sleep",
					"Mutual exclusion in type does not work (thread), message \"#{message}\"")
			}
			thread_was_run = true
		}
		while thread.alive?
			skip, message = type.verify(0, 1, false, ["non-sleep"], type)
			assert(skip == nil, "Bug in test_verify_lock test class (main)") unless main_was_run
			assert(message == "Arg 0 non-sleep", "Mutual exclusion in type does not work (main), message \"#{message}\"") unless main_was_run
			main_was_run = true
		end
		assert(thread_was_run, "We never got to run the side thread")
		assert(main_was_run, "We never got to run the main test code")
		Thread.abort_on_exception = old_abort
	end
	#
	# Test handling of types that do not explictly set an error message
	# when they do not match.
	#
	# Subtests:
	#	- Test that our code do NOT keep the mutex after a failure (so
	#	  two failures can occur after each other)
	#	- Test that the message sent is the correct one
	#
	def test_type_nomessage
		type = nil
		assert_nothing_raised("Defining types for non-set_message thread test") {
			# It is not possible to set the name of a class without
			# assigning it to a constant.  Or by overriding name as
			# below.
			typeclass = Class.new(Type)
			typeclass.module_eval <<-eom
				def ===(other, set_message=false)
					false
				end
				def self.name
					"<anonymous>"
				end
			eom
			type = typeclass.create("test_type_nomessage create")
		}
		thread_was_run = false
		main_was_run = false
		old_abort = Thread.abort_on_exception
		Thread.abort_on_exception = true
		assert_nothing_raised("Running setup of unlock verification in main") {
			skip, message = type.verify(0, 1, false, ["test1"], type)
			assert(skip == nil, "Bug in test_verify_lock test class (main)")
			assert(message == "Arg 0 is not compatible with <anonymous>(\"test_type_nomessage create\")",
				"Mutual exclusion in type does not work (main), message #{message.inspect}")
		}
		thread = Thread.new {
			assert_nothing_raised("Running unlock verification in thread") {
				skip, message = type.verify(0, 1, false, ["test2"], type)
				assert(skip == nil, "Bug in test_verify_lock test class (thread)")
				assert(message == "Arg 0 is not compatible with <anonymous>(\"test_type_nomessage create\")",
					"Mutual exclusion in type does not work (thread), message #{message.inspect}")
			}
			thread_was_run = true
		}
		sleep(1)
		assert(!thread.alive?, "Thread still running when it should be finished")
		assert(thread_was_run, "We never got to run the side thread")
		Thread.abort_on_exception = old_abort
	end
	#
	# Test that the code to detect multiple calls to set_message (AKA calls
	# to set_message when we do not get an error)
	#
	# XXX This do not test the corresponding check in verify, which checks that nobody ELSE
	# has locked the local mutex when verify get called.  That check will be triggered if
	# a verify is called without a set_message while a corresponding
	# set_message has been executed in a different thread.  However, testing that requires
	# generation of new threads and sleeps to trigger the race, and I am
	# getting tired of slowing down my test runs.
	def test_type_set_message_varying
		type = nil
		assert_nothing_raised("Defining types for non-set_message thread test") {
			typeclass = Class.new(Type)
			typeclass.module_eval <<-eom
				def ===(other, set_message=false)
					set_message("Parameter was " + other.to_s)
					other
				end
				def self.name
					"<anonymous>"
				end
			eom
			# Unique parameters to work around that we are an instance of Type,
			# but have different behaviour, and Type.create caches.
			type = typeclass.create("test_type_set_message_varying create")
		}
		assert_raises_msg(RuntimeError,
			"Bug in Type <anonymous>: Varying calls to set_message",
			"Detection of incorrect calls to set_message") {
			type === true
			type === true
		}
	end
	#
	# Test that the default Type.normalize_args works
	#
	def test_type_normalize_args
	    args1 = Type.normalize_args(["string", "string"])
	    args2 = Type.normalize_args(["string", "string"])
	    assert(args1 == args2, "Different args returned by normalize?")
	    args1.each_index { |i|
		assert(args1[i].__id__ == args2[i].__id__, "Trivial normalize_args failed for arg #{i}")
	    }
	    args1 = Type.normalize_args(["string", ["array", "of", "string"], Object])
	    args2 = Type.normalize_args(["string", ["array", "of", "string"], Object])
	    assert(args1 == args2, "Different args returned by normalize?")
	    args1.each_index { |i|
		assert(args1[i].__id__ == args2[i].__id__, "Simple normalize_args failed for arg #{i}")
	    }
	end
	#
	# XXX Array checks recently had a bug where the next N args are skipped,
	# where N is the number of elements in the array.  There should be a
	# test that catch if this bug recurs.
	#

	#
	# Test that the aspects of Type::Any that are not tested by the array
	# tests above works as they should.
	#
	def test_type_any
		# XXX Needs to test the number of args consumed, and that needs
		# Type::Multi.
	end

	#
	# Test that Type::All works as it should
	#
	def test_type_all
		# XXX In order to test this properly, we need Type::Multi
	end

	#
	# Test that Type::Multi does its job.
	#
	def test_type_multi
		tmp = Type::Multi(String, Integer)
		skip = string = nil
		assert_nothing_raised("Simple Type::Multi test") {
			skip, string = tmp.verify(0, -1, false, ["test", 1], tmp)
		}
		assert(skip == 2, "Wrong return (skip) from Type::Multi")
		assert(string == nil, "Wrong return (string) from Type::Multi")
		assert_nothing_raised("Simple Type::Multi failure test") {
			skip, string = tmp.verify(0, -1, [1, 1], tmp)
		}
		assert(string != nil, "Wrong return (string nil) from Type::Multi")
		assert(skip == nil, "Wrong return (skip not nil) from Type::Multi")
		assert_nothing_raised("Simple Type::Multi failure test") {
			skip, string = tmp.verify(0, -1, false, ["test", "test"], tmp)
		}
		assert(string != nil, "Wrong return (string nil 2) from Type::Multi")
		assert(skip == nil, "Wrong return (skip not nil 2) from Type::Multi")
	end
	#
	# Test that using TypeChecker both in a parent and child class works
	#
	def test_dual_include
		parentclass = @tc
		childclass = nil
		anontype = nil
		assert_nothing_raised("Test of dual include (parent and child)") {
			childclass = Class.new(parentclass)
			childclass.instance_eval { include TypeChecker }
		}
		assert_nothing_raised("Creating anonymous Type") {
			anontype = Class.new(Type)
			anontype.module_eval <<-eom
				def self.accessed
					@@accessed
				end
				def initialize(*args)
					@@accessed = 0
					super
				end
				def ===(other, set_message = nil)
					@@accessed += 1
					other
				end
				def self.name
					"<anonymous>"
				end
				def freeze
				end
			eom
		}
		assert_nothing_raised("Adding sig'ed method to child class") {
			childclass.module_eval <<-eom
				typesig anontype.create
				def testmethod(stuff)
				end
			eom
		}
		assert_nothing_raised("Calling typesig'ed method") {
			tmpobj = childclass.new
			tmpobj.testmethod(true)
		}
		assert(anontype.accessed == 1, "Repeated typesig calls")
	end
	#
	# Test adding of class methods
	#
	def test_class_methods
		@tc.module_eval {
			typesig String
			def self.mytest(string)
			end
		}
		assert_nothing_raised("Calling class method with OK parameters") {
			@tc.mytest("ok")
		}
		assert_raises_msg(ArgumentError,
			"Arg 0 is of invalid type (expected String, got Fixnum)",
			"Calling class method with bad parameters") {
			@tc.mytest(1)
		}
	end
	#
	# XXX Should be dynamically constructed in test_dual_typesig
	#
	class TestClass
		include TypeChecker
		def initialize
			@called = 0
		end
		attr_reader :called
		typesig String
		def testm(string)
			@called += 1
		end
	end
	#
	# Test that we call a method correctly after it has had two typesigs added
	#
	def test_dual_typesig
		testobj = nil
		assert_nothing_raised("Generating test object") {
			testobj = TestClass.new
		}
		assert(testobj.called == 0, "TestClass start out wrong")
		assert_nothing_raised("Simple call to testm, first typesig") {
			testobj.testm("ok")
		}
		assert_raises_msg(ArgumentError,
			"Arg 0 is of invalid type (expected String, got Fixnum)",
			"Calling testm (1st sig) with wrong args") {
			testobj.testm(1)
		}
		assert(testobj.called == 1, "TestClass.testm does not inc call count")
		assert_nothing_raised("Changing typesig on TestClass.testm") {
			TestClass.set_typesig(:testm, Integer)
		}
		testobj2 = nil
		assert_nothing_raised("Generating test object 2") {
			testobj2 = TestClass.new
		}
		assert(testobj2.called == 0, "TestClass 2 start out wrong")
		assert_nothing_raised("Second typesig on testm") {
			testobj2.testm(1)
		}
		assert_raises_msg(ArgumentError,
			"Arg 0 is of invalid type (expected Integer, got String)",
			"Calling testm (1st sig) with wrong args") {
			testobj.testm("bad")
		}
		assert(testobj2.called == 1, "TestClass.testm 2 does not inc call count")
	end
	#
	# Test that :arity works
	# XXX We should also have proper normalization tests for this
	#
	# XXX Feature not implemented
	def notest_option_arity
		assert_nothing_raised("Adding a test method to @tc") {
			@tc.module_eval {
				def self.mytest(*args)
				end
			}
		}
		tmpobj = nil
		assert_nothing_raised("Simple call + setup") {
			@tc.mytest(1, 2, 3)
			@tc.set_ctypesig :arity, 1, String
		}
		assert_nothing_raised("OK call") {
			@tc.mytest("ok")
		}
		assert_raises_msg(ArgumentError, "", "Passes bad arity calls") {
			@tc.mytest("bad", "bad", "bad")
		}
	end
	#
	# Test that a particular type passes/fails a set of arguments.
	# Also checks that the correct skip is returned (with nil saying
	# anything Integer is OK for pass), and allows testing of exact
	# specs.
	#
	def type_works(type, passed, failed, skip=nil, msg=nil, exact=false)
		tmsg = "type_works(#{type.inspect})"
	  	rskip = nil
		rmsg = nil
	  	assert_nothing_raised("type_works pass for #{type.class.name}") {
	  		rskip, rmsg = type.verify(0, 1, exact, [passed], Type::Sig(type))
		}
		assert((!rskip && rmsg) || (rskip && !rmsg), "#{tmsg}: Inconsistent skip/msg (on pass)")
		assert(!rmsg, "#{tmsg}: Failure for data that should pass (message #{rmsg.inspect}")
		assert(rskip.kind_of?(Integer), "#{tmsg}: Non-Integer skip")
		assert(!skip || rskip == skip, "#{tmsg}: Wrong skip (pass)")
	  	assert_nothing_raised("type_works fail for #{type.class.name}") {
	  		rskip, rmsg = type.verify(0, 1, exact, [failed], Type::Sig(type))
		}
		assert((!rskip && rmsg) || (rskip && !rmsg), "#{tmsg}: Inconsistent skip/msg (on fail)")
		assert(rmsg, "#{tmsg}: Pass for data that should fail")
		assert(rmsg.kind_of?(String), "#{tmsg}: Wrong data type for message")
		assert(!msg || rmsg == msg, "#{tmsg}: Wrong message (#{rmsg.inspect} instead of #{msg.inspect})")
	end
	#
	# Test that Type::Not works
	#
	def test_type_not
	end
	#
	# Test that Type::Range works
	#
	def test_type_range
	    type_works(Type::Range(nil, 10), 10, 11, 1, "Arg 0 is larger than 10")
	    type_works(Type::Range(5,   10), 10, 11, 1, "Arg 0 is larger than 10")
	    type_works(Type::Range(10, nil), 10,  1, 1, "Arg 0 is smaller than 10")
	    type_works(Type::Range(5, 10),   10,  1, 1, "Arg 0 is smaller than 5")
	    assert_raises_msg(ArgumentError, "max (5) < min (10)", "Creation of out-of-order range") {
		Type::Range(10, 5)
	    }
	    assert_raises_msg(ArgumentError, "double nil", "Creation of nil range") {
		Type::Range(nil, nil)
	    }
	end
	#
	# Test that Type::NotNil works
	#
	def test_type_notnil
	    type_works(Type::NotNil(), true, nil,   1, "Arg 0 is nil")
	    type_works(Type::NotNil(), Object, nil, 1, "Arg 0 is nil")
	end
	#
	# Test that Type::Regexp works
	#
	def test_type_regexp
	    type_works(Type::Regexp(/^[a-z0-9]/), "abdi123%%", "%asd", 1,
	    	"Arg 0 is not compatible with Type::Regexp(/^[a-z0-9]/)")
	end
	#
	# Test that Type:;Hash works
	#
	def test_type_hash
	    # Test normalization
	    type1 = Type::Hash({ 'arg1' => Type::Equals('value') })
	    type2 = Type::Hash({ 'arg1' => Type::Equals('value') })
	    assert(type1 == type2, "Bad normalization of Type::Hash")
	    assert(type1.__id__ == type2.__id__, "Bad normalization of Type::Hash (id)")
	    # Test generic type functionality
	    type_works(Type::Hash({ 'arg1' => String }), { 'arg1' => "string" }, 
	    	nil, 1, "Arg 0 is not hash type")
	    type_works(Type::Hash({ 'arg1' => String }), { 'arg1' => "string" },
		{ 'arg1' => Object }, 1, "Arg 0 key arg1 (a Class) does not match String")
	    type_works(Type::Hash({ 'arg1' => String }), { 'arg1' => "string" },
		{}, 1, "Arg 0 miss key \"arg1\"")
	end
	#
	# Test that Type::Equals works
	#
	def test_type_equals
	    assert(Type::Equals(Class) === Class, "Class against Class")
	    assert(!(Type::Equals(Class) === Object), "Fail Class against Object")
	end
	#
	# Test that Type::Boolean works
	#
	def test_type_boolean
	    assert(Type::Boolean() === true, "Boolean against true")
	    assert(Type::Boolean() === false, "Boolean against false")
	    assert(!(Type::Boolean() === Object), "Boolean against Object")
	end
	# XXX Problem in Test::Unit:
	# Assertion failures should show backtrace out until the end of the
	# test method presently being run, in order to more easily debug
	# failures.
end

#
# Test the Type class itself, directly
#
class Type__TestClass < Test::Unit::TestCase
    class DumbString < String
	undef_method :hash
    end
    def test_normalize_ref
	# Verify that we can normalize a simple string
	arg =  Type.normalize_ref("nada")
	arg2 = Type.normalize_ref("nada")
	assert(arg == arg2, "Cannot normalize String")
	assert(arg.__id__ == arg2.__id__, "Cannot normalize String (id)")
	ds  = DumbString.new("nada")
	ds2 = DumbString.new("nada")
	assert(ds.id != ds2.id, "Equal dumbstrings are collapsed outside our control!")
	assert(ds == ds2, "Equal dumbstrings are different?!?")
	arg  = Type.normalize_ref(ds)
	assert(arg.id != arg2, "Different classes with equal content are considered the same")
	arg2 = Type.normalize_ref(ds2)
	assert(arg.id == arg2.id, "Equal items are not collapsed")

	arg =  Type.normalize_ref({ 'key' => 'value'})
	arg2 = Type.normalize_ref({ 'key' => 'value'})
	assert(arg == arg2, "Cannot normalize Hash")
	assert(arg.__id__ == arg2.__id__, "Cannot normalize Hash (id)")

	arg =  Type.normalize_ref(['test'])
	arg2 = Type.normalize_ref(['test'])
	assert(arg == arg2, "Cannot normalize Array")
	assert(arg.__id__ == arg2.__id__, "Cannot normalize Array (id)")
    end
end

class MiscTests < Test::Unit::TestCase
    #
    # Verify that Module === works the way I think it should
    #
    def test_module_treequals
	assert(Object === Class, "Class not a kind of Object?")
	assert(Class === Object, "Object not a kind of Class?")
	assert(Enumerable === [], "An array is not a kind of Enumerable?")
	assert(!(Enumerable === Object), "An Object is a kind of Enumerable?")
    end
end
