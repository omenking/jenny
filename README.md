jenny
==========

def user_partial user
  html = render partial: 'users/user', locals: { user: user }
  content_tag :div, html, class: 'user'
end

def user_partial user
  parital '.user', user: user
end
