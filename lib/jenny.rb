require 'admin_panel/version'
require 'admin_panel/jenny_helper'

module AdminPanel
  ActionView::Base.send :include, JennyHelper
end
