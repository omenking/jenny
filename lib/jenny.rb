require 'jenny/version'
require 'jenny/jenny_helper'

module Jenny
  ActionView::Base.send :include, JennyHelper
end
