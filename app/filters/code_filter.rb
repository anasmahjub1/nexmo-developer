class CodeFilter < Banzai::Filter
  def call(input)
    input.gsub(/```code(.+?)```/m) do |_s|
      config = YAML.safe_load($1)

      if config['config']
        configs = YAML.load_file("#{Rails.root}/config/code_examples.yml")
        config = config['config'].split('.').inject(configs) { |h, k| h[k] }
      end

      code = File.read("#{Rails.root}/#{config['source']}")
      language = File.extname("#{Rails.root}/#{config['source']}")[1..-1]
      lexer = language_to_lexer(language)

      total_lines = code.lines.count

      # Minus one since lines are not zero-indexed
      from_line = (config['from_line'] || 1) - 1
      to_line = (config['to_line'] || total_lines) - 1

      code = code.lines[from_line..to_line].join

      highlighted_source = highlight(code, lexer)

      line_numbers = (1..total_lines).map do |line_number|
        <<~HEREDOC
          <span class="focus__lines__line">#{line_number}</span>
        HEREDOC
      end

      <<~HEREDOC
        <pre class="highlight #{lexer.tag}"><code>#{highlighted_source}</code></pre>
      HEREDOC
    end
  end

  private

  def highlight(source, lexer)
    formatter = Rouge::Formatters::HTML.new
    formatter.format(lexer.lex(source))
  end

  def language_to_lexer(language)
    Rouge::Lexer.find(language.downcase) || Rouge::Lexer.find('text')
  end
end
