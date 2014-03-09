# アプリ名の取得
@app_name = app_name

# add to Gemfile
append_file 'Gemfile', <<-CODE

# turbolinks support
gem 'jquery-turbolinks'

# CSS Support
gem 'less-rails'

# Haml
gem 'haml-rails'

# Pagenation
gem 'kaminari'

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

end

CODE

# install gems
run 'bundle install'
