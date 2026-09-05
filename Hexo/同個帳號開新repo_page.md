

## 在帳號建立 repo

new repo
name : journal


## github page 設定

repo => settings => Pages

Source : Deploy from branch
Branch : master , root

=> save


## local hexo


1. 建立新資料夾
2. 設定 config.yaml

```bash
#Deployment
##https://hexo.io/docs/one-command-deployment.html
deploy:
  type: git
  repo: https://github.com/CHI-KEKE/journal.git
  branch: master
```

3. 設定 config.yml

```bash
# Hexo Configuration
## Docs: https://hexo.io/docs/configuration.html
## Source: https://github.com/hexojs/hexo/

# Site
title: 平屋慢生活
subtitle: 腦中的思考
description: ''
keywords:
author: Yo-Lin
language: zh
timezone: ''

# URL
## Set your site url here. For example, if you use GitHub Page, set url as 'https://username.github.io/project'
url: https://chi-keke.github.io/journal
root: /journal/
permalink: :year/:month/:day/:title/
permalink_defaults:
pretty_urls:
  trailing_index: false # Set to false to remove trailing 'index.html' from permalinks
  trailing_html: false # Set to false to remove trailing '.html' from permalinks

# Directory
source_dir: source
public_dir: public
tag_dir: tags
archive_dir: archives
category_dir: categories
code_dir: downloads/code
i18n_dir: :lang
skip_render:

# Writing
new_post_name: :.md # File name of new posts
default_layout: post
titlecase: false # Transform title into titlecase
external_link:
  enable: true # Open external links in new tab
  field: site # Apply to the whole site
  exclude: ''
filename_case: 0
render_drafts: false
post_asset_folder: true
relative_link: false
future: true
syntax_highlighter: highlight.js
highlight:
  line_number: true
  auto_detect: true
  tab_replace: ''
  wrap: true
  hljs: false
prismjs:
  enable: false
  preprocess: true
  line_number: true
  tab_replace: ''

# Home page setting
# path: Root path for your blogs index page. (default = '')
# per_page: Posts displayed per page. (0 = disable pagination)
# order_by: Posts order. (Order by date descending by default)
index_generator:
  path: ''
  per_page: 10
  order_by: -date

# Category & Tag
default_category: uncategorized
category_map:
tag_map:

# Metadata elements
## https://developer.mozilla.org/en-US/docs/Web/HTML/Element/meta
meta_generator: true

# Date / Time format
## Hexo uses Moment.js to parse and display date
## You can customize the date format as defined in
## http://momentjs.com/docs/#/displaying/format/
date_format: YYYY-MM-DD
time_format: HH:mm:ss
## updated_option supports 'mtime', 'date', 'empty'
updated_option: 'mtime'

# Pagination
## Set per_page to 0 to disable pagination
per_page: 10
pagination_dir: page

# Include / Exclude file(s)
## include:/exclude: options only apply to the 'source/' folder
include:
exclude:
ignore:

# Extensions
## Plugins: https://hexo.io/plugins/
## Themes: https://hexo.io/themes/
theme: butterfly


# 留言區
envelope_comment:
enable: true
cover: https://i.imgur.com/GZaVPlE.png # 信笺封面图
message:
  - 有什麼想吐槽的？
bottom: Hi!   # 信笺结束语，只能单行
height:                          # 调整信笺划出高度，默认1050px
path:                            # 【可选】comments 的路径名称。默认为 comments ， 生成的页面为 comments/index.html
front_matter:                    # 【可选】comments页面的 front_matter 配置
  title: 留言板
  comments: false
  aside: false

# Deployment
## Docs: https://hexo.io/docs/one-command-deployment
deploy:
  type: git
  repo: https://github.com/CHI-KEKE/journal.git
  branch: master 
```


## hexo-cli 指令


```bash
hexo init
npm install
npm install hexo-deployer-git --save
npm install cheerio@0.22.0 --save
npm install hexo-renderer-pug hexo-renderer-stylus --save
git clone -b dev https://github.com/jerryc127/hexo-theme-butterfly.git themes/butterfly
```

## butterfly

1. copy en 的 yaml