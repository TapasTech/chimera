# Chimera 稿件去重模块
![logo](https://raw.githubusercontent.com/TapasTech/chimera/master/chimera.jpg)


## 基本使用方法

1. 在 settings.yml 中配置算法参数

  ```
  dedup_algrithms:  

    # 自动去重算法配置, has_dup? 方法默认应用该算法配置
    auto:
      score_lower_bound:        150
      size_diff_upper_bound:    0.25
      phrases_diff_upper_bound: 0.25

    # 批量去重算法配置, 可以在 duplication_reports 中传参数 :batch 调用
    batch:
      score_lower_bound:        80
      size_diff_upper_bound:    0.5
      phrases_diff_upper_bound: 0.5
  ```

2. 在 model 中 include 相关模块

  ```
  class Document
    include Mongoid::Document
    include Mongoid::Timestamps
    include Elasticsearch::Model
    include Dedup::Dedupable
    include Dedup::Elasticsearchable

    field :content,     type: String
    field :origin_date, type: ActiveSupport::TimeWithZone
  end
  ```

3. 在 model 上调用相关方法

  ```
  doc = Document.sample

  doc.has_dup?
  # => true or false

  doc.duplication_reports(:batch)
  # => [{
  #   :id=>"55b0c7b46c697452170001a7",
  #   :score=>187.7253,
  #   :size_diff=>0.0,
  #   :phrases_diff=>0.5
  # }]
  ```
