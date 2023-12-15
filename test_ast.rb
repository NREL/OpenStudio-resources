# frozen_string_literal: true

require 'parser/current'
require 'rubocop-ast'
require 'rubocop'
class Rule < Parser::AST::Processor
  include RuboCop::AST::Traversal

  def initialize(rewriter)
    @rewriter = rewriter
  end

  def create_range(begin_pos, end_pos)
    Parser::Source::Range.new(@rewriter.source_buffer, begin_pos, end_pos)
  end
end

class IndentationRule < Rule
  include RuboCop::Cop::Layout::IndentationWidth
  extend AutoCorrector

  def initialize(rewriter)
    super()
    @rewriter = rewriter
  end

  # Your additional methods or modifications can go here
end
code = <<~RUBY
  10.times do |i|
  if i == 0
             puts "zero"
      elsif i == 4
  puts "4"
  else
    if i < 5 or i > 10
      puts "wrong"
  end
    end
  end
RUBY

source = RuboCop::AST::ProcessedSource.new(code, 2.7)
source_buffer = source.buffer
rewriter = Parser::Source::TreeRewriter.new(source_buffer)
rule = IndentationRule.new(rewriter)
source.ast.each_node { |n| rule.process(n) }
puts rewriter.process
