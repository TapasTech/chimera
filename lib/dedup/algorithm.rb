class Dedup::Algorithm
  def initialize(data, attributes={})
    @max_query_terms          = attributes[:max_query_terms]          || 200
    @score_lower_bound        = attributes[:score_lower_bound]        || 130
    @size_diff_upper_bound    = attributes[:size_diff_upper_bound]    || 1
    @phrases_diff_upper_bound = attributes[:phrases_diff_upper_bound] || 1
    @should_title_match       = attributes[:should_title_match]       || false
    @origin_date_from_ago     = attributes[:origin_date_from_ago]     || 2.weeks
    @data = data
  end

  def setup_elasticsearch_query(searcher)
    searcher.should :more_like_this, {
      fields: ['content'],
      like: text_of(@data[:content]),
      max_query_terms: @max_query_terms,
      min_term_freq:   1
    }
    searcher.must :range, origin_date: {
      gt:  @data[:origin_date] - @origin_date_from_ago,
      lte: @data[:origin_date]
    }
    searcher.must_not :term, id: @data[:id].to_s
  end

  def enough?(results, size)
    results.blank?                           ||
    results.size       <  size               ||
    results[-1]._score <  @score_lower_bound ||
    results.size       >= @max_query_terms   and results
  end

  def report(result)
    { id:           result._id,
      score:        result._score,
      size_diff:    size_diff(text_of(result.content), text_of(@data[:content])),
      phrases_diff: phrases_diff(text_of(result.content), text_of(@data[:content]))
    }
  end

  def is_dup?(report)
    report[:score]        >  @score_lower_bound        &&
    report[:size_diff]    <= @size_diff_upper_bound    &&
    report[:phrases_diff] <= @phrases_diff_upper_bound
  end

private

  def text_of(content)
    Nokogiri::HTML(content).content.gsub(/[\s\u200d\u00a0\u3000]/, '')
  end

  # 计算两篇文章的长度差异率
  def size_diff(*texts)
    sizes = texts.map(&:size)
    sizes.reduce(:-).abs.to_f / sizes.max
  end

  # 计算两篇文章的短语差异率
  def phrases_diff(*texts)
    phrases = texts.map(&method(:phrases_of)).sort_by(&:size).reverse
    phrases.reduce(:-).size.to_f / phrases.first.size
  end

  # 找到文章中的所有短语
  def phrases_of(text)
    text.split(/\p{P}/).lazy.map(&:utf8_strip).select(&:present?).to_a.uniq
  end

  String.class_eval do
    def utf8_strip
      self.gsub(/(\A[\u00a0\s\u3000]+|[\u00a0\s\u3000]+\Z)/, "")
    end unless String.instance_methods.include?(:utf8_strip)
  end
end
