# アプリ名の取得
@app_name = app_name

# add to Gemfile
append_file 'Gemfile', <<-CODE

gem 'debugger', group: [:development, :test]

# turbolinks support
gem 'jquery-turbolinks'

# See https://github.com/sstephenson/execjs#readme for more supported runtimes
# use twitter-bootstrap-rails
#gem 'therubyracer', platforms: :ruby

# CSS Support
#gem 'less-rails'

# Haml
gem 'haml-rails'

# Assets log cleaner
gem 'quiet_assets'

# Pagenation
gem 'kaminari'

gem 'simple_form'

#gem 'twitter-bootstrap-rails'

# HTML5 Validator
gem 'html5_validators'

group :development do
  # Converter erb => haml
  gem 'erb2haml'
end

group :development, :test do
  # Railsコンソールの多機能版
  gem 'pry-rails'

  # pryの入力に色付け
  gem 'pry-coolline'

  # デバッカー
  gem 'pry-byebug'

  # Pryでの便利コマンド
  gem 'pry-doc'

  # PryでのSQLの結果を綺麗に表示
  gem 'hirb'
  gem 'hirb-unicode'

  # pryの色付けをしてくれる
  gem 'awesome_print'

  # Rspec
  gem 'rspec-rails'
  gem 'rake_shared_context'

  # fixtureの代わり
  gem 'factory_girl_rails'

  # テスト環境のテーブルをきれいにする
  gem 'database_rewinder'

  # Guard
  gem 'guard-rspec'
  gem 'guard-spring'

  # Error見やすく
  gem 'better_errors'

end

CODE

if yes?("This app will be following up on both the smartphone and PC?")
  gem 'jpmobile'
end

# install gems
run 'bundle install'

# set config/application.rb
application  do
  %q{
    # Set timezone
    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local

    # 日本語化
    I18n.enforce_available_locales = true
    config.i18n.load_path += Dir[Rails.root.join('config', 'locales', '**', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :ja

    # generatorの設定
    config.generators do |g|
      g.orm :active_record
      g.template_engine :haml
      g.test_framework  :rspec, :fixture => true
      g.fixture_replacement :factory_girl, :dir => "spec/factories"
      g.view_specs false
      g.controller_specs false
      g.routing_specs false
      g.helper_specs false
      g.request_specs false
      g.assets false
      g.helper false
    end

    # libファイルの自動読み込み
    config.autoload_paths += %W(#{config.root}/lib)
    config.autoload_paths += Dir["#{config.root}/lib/**/"]
  }
end

# set Japanese locale
run 'wget https://raw.github.com/emuy/template/master/locales/ja.yml -P config/locales/'

# HAML 
run 'rake haml:replace_erbs'

# Bootstrap/Bootswach/Font-Awaresome
#insert_into_file 'app/views/layouts/application.html.haml',%(
#%script{:src=>'//netdna.bootstrapcdn.com/bootstrap/3.0.3/js/bootstrap.min.js'}
#%link{:href=>'//netdna.bootstrapcdn.com/font-awesome/4.0.3/css/font-awesome.min.css', :rel=>'stylesheet'}
#%link{:href=>'//netdna.bootstrapcdn.com/bootswatch/3.0.3/simplex/bootstrap.min.css', :rel=>'stylesheet'}
#), after: '= csrf_meta_tags'

# Simple Form
#generate 'simple_form:install --bootstrap'
generate 'simple_form:install'

# Rspec/Spring/Guard
# ----------------------------------------------------------------
# Rspec
generate 'rspec:install'
run "echo '--color --drb -f d' > .rspec"

insert_into_file 'spec/spec_helper.rb',%(
  config.before :suite do
    DatabaseRewinder.clean_all
  end

  config.after :each do
    DatabaseRewinder.clean
  end

  config.before :all do
    FactoryGirl.reload
    FactoryGirl.factories.clear
    FactoryGirl.sequences.clear
    FactoryGirl.find_definitions
  end

  config.include FactoryGirl::Syntax::Methods
), after: 'RSpec.configure do |config|'

insert_into_file 'spec/spec_helper.rb', "\nrequire 'factory_girl_rails'", after: "require 'rspec/rails'"
gsub_file 'spec/spec_helper.rb', "require 'rspec/autorun'", ''

# Spring
run 'wget https://raw.github.com/jonleighton/spring/master/bin/spring -P bin/'
run 'sudo chmod a+x bin/spring'

# Guard
run 'bundle exec guard init'
gsub_file 'Guardfile', 'guard :rspec do', "guard :rspec, cmd: 'spring rspec -f doc' do"

# Setting seed
# ==================================================
run "ehco db/seeds.rb"

run "mkdir -p db/seeds/production"
run "mkdir -p db/seeds/development"
run "mkdir -p db/seeds/test"

run "cat << EOF > db/seeds.rb
# -*- coding: utf-8 -*-
require 'csv'

table_names = %w()

def data_entry(file_path)
  #モデル名に変換
  model_name = File::basename(file_path).sub(/.csv$/,\"\").singularize.camelize
  puts file_path
  header = nil

  CSV.open(file_path,'r').each do |row|
    if header.nil?
      header = row
      # throw Exception.new('ID列が存在しません') unless header[0] == 'id'
      next
    end
    model = eval(model_name)
    record = model.new

    if Rails.env.to_s == 'development'
      record.send('id=',row.count)
    end

    header.each_with_index do |column,index|
      record.send(\"\#{column}=\",row[index]) unless row[index].nil?
    end
    record.save!
  end
end

ActiveRecord::Base.transaction do
  table_names.each do |f|
    file_path = File.join(\"\#{Rails.root.to_s}\",\"db/seeds/\#{Rails.env.to_s}/\#{f}.csv\")
data_entry(file_path)
  end

  Dir::glob(File.join(\"\#{Rails.root.to_s}\",\"db/seeds/\#{Rails.env.to_s}/*.csv\")).each do |file_path|
    unless table_names.index(File::basename(file_path).sub(/.csv$/,\"\"))
      data_entry(file_path)
    end
  end

  Dir::glob(File.join(\"\#{Rails.root.to_s}\",\"db/seeds/\#{Rails.env.to_s}/*.rb\")).each do |file_path|
    puts file_path
    require(file_path) if File.exist?(file_path)
  end
end
EOF"

# Setting custom scaffold
# ==================================================
run "mkdir -p lib/generators/haml/scaffold"
run "mkdir -p lib/templates/rails/controller"
run "mkdir -p lib/templates/rails/helper"
run "mkdir -p lib/templates/rails/scaffold_controller"
run 'wget https://raw.github.com/emuy/template/master/lib/generators/haml/scaffold/scaffold_generator.rb -P lib/generators/haml/scaffold/'
run 'wget https://raw.github.com/emuy/template/master/templates/rails/controller/controller.rb -P lib/templates/rails/controller/'
run 'wget https://raw.github.com/emuy/template/master/templates/rails/helper/helper.rb -P lib/templates/rails/helper/'
run 'wget https://raw.github.com/emuy/template/master/templates/rails/scaffold_controller/controller.rb -P lib/templates/rails/scaffold_controller/'
# Setting custom scaffold (Views)
run 'wget https://raw.github.com/emuy/template/master/templates/haml/scaffold/edit.html.haml -P lib/templates/haml/scaffold/'
run 'wget https://raw.github.com/emuy/template/master/templates/haml/scaffold/index.html.haml -P lib/templates/haml/scaffold/'
run 'wget https://raw.github.com/emuy/template/master/templates/haml/scaffold/new.html.haml -P lib/templates/haml/scaffold/'
run 'wget https://raw.github.com/emuy/template/master/templates/haml/scaffold/show.html.haml -P lib/templates/haml/scaffold/'
# delete _form.html.haml
run 'rm lib/templates/haml/scaffold/_form.html.haml'
run 'wget https://raw.github.com/emuy/template/master/templates/haml/scaffold/_form.html.haml -P lib/templates/haml/scaffold/'

# set application_controller.rb
insert_into_file 'app/controllers/application_controller.rb', "# coding: utf-8\n", before: "class ApplicationController < ActionController::Base"

# set .ruby-version
run 'wget https://raw.github.com/emuy/template/master/.ruby-version'

# set .gitignore
run 'rm .gitignore'
run 'wget https://raw.github.com/emuy/template/master/.gitignore'

# Use Google Map
if yes?("Use Google Map?")
  # set Google Map
  gem 'gmaps4rails'
  gem 'geocoder'

  # install gems
  run 'bundle install'

  # set underscore.js
  run 'wget -P app/javascripts/underscore.js http://underscorejs.org/underscore-min.js'
  #run 'wget -O underscore.js http://underscorejs.org/underscore-min.js -P app/assets/javascripts/'
  #run 'wget -O app/assets/javascripts/underscore.js http://underscorejs.org/underscore-min.js -P'

  # set application.js
  insert_into_file 'app/assets/javascripts/application.js', "\n//= require underscore", after: "//= require turbolinks"
  insert_into_file 'app/assets/javascripts/application.js', "\n//= require gmaps/google", after: "//= require underscore"

  # set _google_map.html.haml
  run 'wget https://raw.github.com/emuy/template/master/_google_map.html.haml -P app/views/layouts/'

  # add _google_map.html.haml at application.html.haml
  insert_into_file 'app/views/layouts/application.html.haml', "\n    = render 'layouts/google_map'", after: "= javascript_include_tag \"application\", \"data-turbolinks-track\" => true"
end

# git init
# ----------------------------------------------------------------
git :init
git :add => '.'
git :commit => "-a -m 'first commit'"