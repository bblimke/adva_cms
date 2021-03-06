#!/usr/local/bin/ruby -w

$TESTING = true

$: << 'lib'

require 'minitest/autorun'
require 'ruby2ruby'
require 'pt_testcase'
require 'fileutils'
require 'tmpdir'

class R2RTestCase < ParseTreeTestCase
  def self.previous key
    "ParseTree"
  end

  def self.generate_test klass, node, data, input_name, output_name
    output_name = data.has_key?('Ruby2Ruby') ? 'Ruby2Ruby' : 'Ruby'

    klass.class_eval <<-EOM
      def test_#{node}
        pt = #{data[input_name].inspect}
        rb = #{data[output_name].inspect}

        refute_nil pt, \"ParseTree for #{node} undefined\"
        refute_nil rb, \"Ruby for #{node} undefined\"

        assert_equal rb, @processor.process(pt)
      end
    EOM
  end
end

start = __LINE__

class TestRuby2Ruby < R2RTestCase
  def setup
    super
    @processor = Ruby2Ruby.new
  end

  def test_dregx_slash
    inn = util_thingy(:dregx)
    out = "/blah\\\"blah#\{(1 + 1)}blah\\\"blah\\/blah/"
    util_compare inn, out, /blah\"blah2blah\"blah\/blah/
  end

  def test_dstr_quote
    inn = util_thingy(:dstr)
    out = "\"blah\\\"blah#\{(1 + 1)}blah\\\"blah/blah\""
    util_compare inn, out, "blah\"blah2blah\"blah/blah"
  end

  def test_dsym_quote
    inn = util_thingy(:dsym)
    out = ":\"blah\\\"blah#\{(1 + 1)}blah\\\"blah/blah\""
    util_compare inn, out, :"blah\"blah2blah\"blah/blah"
  end

  def test_lit_regexp_slash
    util_compare s(:lit, /blah\/blah/), '/blah\/blah/', /blah\/blah/
  end

  def test_call_self_index
    util_compare s(:call, nil, :[], s(:arglist, s(:lit, 42))), "self[42]"
  end

  def test_call_self_index_equals
    util_compare(s(:call, nil, :[]=, s(:arglist, s(:lit, 42), s(:lit, 24))),
                 "self[42] = 24")
  end

  def test_masgn_wtf
    inn = s(:block,
            s(:masgn,
              s(:array, s(:lasgn, :k), s(:lasgn, :v)),
              s(:array,
                s(:splat,
                  s(:call,
                    s(:call, nil, :line, s(:arglist)),
                    :split,
                    s(:arglist, s(:lit, /\=/), s(:lit, 2)))))),
            s(:attrasgn,
              s(:self),
              :[]=,
              s(:arglist, s(:lvar, :k),
                s(:call, s(:lvar, :v), :strip, s(:arglist)))))

    out = "k, v = *line.split(/\\=/, 2)\nself[k] = v.strip\n"

    util_compare inn, out
  end


  def test_masgn_splat_wtf
    inn = s(:masgn,
            s(:array, s(:lasgn, :k), s(:lasgn, :v)),
            s(:array,
              s(:splat,
                s(:call,
                  s(:call, nil, :line, s(:arglist)),
                  :split,
                  s(:arglist, s(:lit, /\=/), s(:lit, 2))))))
    out = 'k, v = *line.split(/\\=/, 2)'
    util_compare inn, out
  end

  def test_splat_call
    inn = s(:call, nil, :x,
            s(:arglist,
              s(:splat,
                s(:call,
                  s(:call, nil, :line, s(:arglist)),
                  :split,
                  s(:arglist, s(:lit, /\=/), s(:lit, 2))))))

    out = 'x(*line.split(/\=/, 2))'
    util_compare inn, out
  end

  def util_compare sexp, expected_ruby, expected_eval = nil
    assert_equal expected_ruby, @processor.process(sexp)
    assert_equal expected_eval, eval(expected_ruby) if expected_eval
  end

  def util_thingy(type)
    s(type,
      'blah"blah',
      s(:call, s(:lit, 1), :+, s(:arglist, s(:lit, 1))),
      s(:str, 'blah"blah/blah'))
  end
end

####################
#         impl
#         old  new
#
# t  old    0    1
# e
# s
# t  new    2    3

tr2r = File.read(__FILE__).split(/\n/)[start+1..__LINE__-2].join("\n")
ir2r = File.read("lib/ruby2ruby.rb")

require 'ruby_parser'

def silent_eval ruby
  old, $-w = $-w, nil
  eval ruby
  $-w = old
end

def morph_and_eval src, from, to, processor
  new_src = processor.new.process(RubyParser.new.process(src.sub(from, to)))
  silent_eval new_src
  new_src
end

____ = morph_and_eval tr2r, /TestRuby2Ruby/, 'TestRuby2Ruby2', Ruby2Ruby
ruby = morph_and_eval ir2r, /Ruby2Ruby/,     'Ruby2Ruby2',     Ruby2Ruby
____ = morph_and_eval ruby, /Ruby2Ruby2/,    'Ruby2Ruby3',     Ruby2Ruby2

class TestRuby2Ruby1 < TestRuby2Ruby
  def setup
    super
    @processor = Ruby2Ruby2.new
  end
end

class TestRuby2Ruby3 < TestRuby2Ruby2
  def setup
    super
    @processor = Ruby2Ruby2.new
  end
end

class TestRuby2Ruby4 < TestRuby2Ruby2
  def setup
    super
    @processor = Ruby2Ruby3.new
  end
end
