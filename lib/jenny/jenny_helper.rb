module JennyHelper
  def app_formatted_path args, options
    namespace = []
    namespace << options[:namespace].to_sym if options.has_key? :namespace
    path = namespace + args
    path
  end

  def app_action_name action, options, element_name=nil
    a_name = []
    a_name << options[:prepend_id].to_sym if options.has_key? :prepend_id
    a_name << action
    a_name << element_name unless element_name.nil?
    a_name = a_name.join('_')
  end

  def app_form_for *args, &proc
    raise ArgumentError, "Missing block" unless block_given?
    options,id_args,target,action,args = shes_just_a_memory(*args)
    options[:style] ||= 'display: none'
    singular_name   = target.class.to_s.underscore
    action_name     = app_action_name action, options, 'form'
    form_path       = options[:url] || app_formatted_path(args,options)

    class_name      = ['app_form',"#{singular_name}_form","#{action}_#{singular_name}_form"]
    class_name      << options[:class] if options[:class]
    class_name      = class_name.join ' '

    loading_args    = id_args.clone
    loading_args    << (options[:after] ? { after: options[:after] } : {} )

    html = {
      class: class_name,
      style: options[:style]
    }

    html.merge! options[:attrs] if options[:attrs]
    form_for target,
      url:    form_path,
      remote: true,
      html:   html,
      &proc
  end

  def app_form *args
    options,id_args,target,action,args = shes_just_a_memory *args
    partial_path = []
    partial_path << options[:namespace] if options.has_key? :namespace
    partial_path << target.class.to_s.tableize
    partial_path = partial_path.join('/')
    locals = {}
    args.each{ |a| locals[a.class.to_s.tableize.singularize.to_sym] = a }
    locals.merge! options[:locals]  if options[:locals]
    partial "#{partial_path}/form", locals
  end


  def show_form_errors target, form_id
    page << "Jenny.remove_form_errors('#{form_id}')"
    target.errors.each do |field,message|
      page << "Jenny.show_form_errors('#{form_id}','#{field}','#{message}')"
    end
  end

  def shes_just_a_memory(*args)
    #And she use to mean so much to me...
    options = args.extract_options!
    id_args = args.dup
    id_args << { :namespace => options[:namespace] } if options.has_key? :namespace
    target = args.last
    action = if options[:method] == :delete
      'delete'
    else
      target.new_record? ? 'new' : 'edit'
    end
    [options,id_args,target,action,args]
  end

  def locals helper_binding, *locals
    options = locals.extract_options!
    result = {}
    vars = eval "local_variables", helper_binding
    for var in vars
      next if var == 'html'
      result[var.to_sym] = eval "#{var}", helper_binding
    end
    result.merge! options
    result.symbolize_keys
  end

  def app_checkbox f,name
    html = ''
    html << f.label(name, t(".#{name}"))
    html << f.check_box(name)
    wrap '.check_box', html
  end

  def app_select f, name, *args
    label_txt  = args[0].is_a?(String)
    options    = label_txt ? {label_txt: args[0]} : args.extract_options!
    any_errors = f.object.errors[name.to_sym].any?
    err_class  = '.err' if any_errors

    table_name     = f.object.class.to_s.tableize.singularize
    select_options = eval "#{table_name}_#{name}_select_options"

    label_html  = app_label    name, options
    select_html = f.select     name, select_options, include_blank: '----'
    error_html  = app_error f, name, options

    html = ''
    html << label_html.to_s
    html << select_html.to_s
    html << error_html.to_s
    html << capture(&block) if block_given?
    html << wrap('.clear')
    html = wrap ".select.#{name}#{err_class}", html
  end

  def app_expand_select f, name, options={}
    opts = eval "#{f.object.class.to_s.tableize.singularize}_#{name}_select_options"
    html = ''
    html << f.label(name, t(".#{name}"))
    html << wrap('.options', opts.collect{|o|wrap('.option', o[0], :value => o[1])}.join.html_safe)
    html << f.hidden_field(name)
    wrap ".expand_select.#{name}", html
  end

  def app_label name, options={}
    include_label = options.delete :include_label
    label_txt     = options.delete :label_txt
    label_txt     = label_txt ? label_txt : t(".#{name}")
    label_tag name, label_txt unless include_label
  end

  def app_error f, name, options={}
    include_error = options.delete :include_error
    any_errors    = f.object.errors[name.to_sym].any?
    error_txt     = options.delete :error_txt
    return unless any_errors
    txt = t(".#{name}")
    txt = error_txt if error_txt
    errors = f.object.errors[name.to_sym]
    errors.map!{|e|"#{txt} #{e}"}
    msg    = errors.join '<br />'
    wrap ".err_msg.#{name}", msg
  end

  # params:
  # form_object, name, options
  # form_option, name, label_txt
  #
  # options:
  #  include_label (default: true) set false to not render label html
  #  include_txt change the label's default text
  #  include_error (default: true) set false to not render error html
  def app_text_field f,name, *args, &block
    label_txt           = args.shift if args[0].is_a?(String)
    options             = args.extract_options!
    options[:label_txt] = label_txt if label_txt
    any_errors          = f.object.errors[name.to_sym].any?
    err_class           = '.err' if any_errors

    label_html = app_label   name, options
    input_html = f.text_field name, options
    error_html = app_error f, name, options

    html = ''
    html << label_html.to_s
    html << input_html.to_s
    html << error_html.to_s
    html << capture(&block) if block_given?
    html = wrap ".text_field.#{name}#{err_class}", html
  end

  def app_password_field f,name,*args
    label_txt  = args[0].is_a?(String)
    options    = label_txt ? {label_txt: args[0]} : args.extract_options!
    any_errors = f.object.errors[name.to_sym].any?
    err_class  = '.err' if any_errors

    label_html = app_label        name, options
    input_html = f.password_field name, options
    error_html = app_error     f, name, options

    html = ''
    html << label_html.to_s
    html << input_html.to_s
    html << error_html.to_s
    html << capture(&block) if block_given?
    html = wrap ".password_field.#{name}#{err_class}", html
  end

  def app_text_field_tag name, *args
    label_txt  = args[0].is_a?(String)
    options    = label_txt ? {label_txt: args[0]} : args.extract_options!
    value    ||= ''
    value      = options.delete :value if options[:value]

    label_html = app_label      name, options
    input_html = text_field_tag name, value

    html = ''
    html << label_html.to_s
    html << input_html.to_s
    html = wrap ".text_field.#{name}", html
  end

  def app_text_area f, name
    html = ''
    html << f.label(name, t(".#{name}"))
    html << f.text_area(name)
    wrap ".text_area.#{name}", html
  end

  def app_hidden_field f, *fields
    fields.collect { |field| f.hidden_field(field) }.join.html_safe
  end

  def wrap selector, *args
    options = args.extract_options!

    render_html = args.shift
    selector = [selector] unless selector.is_a?(Array)

    top    = options.delete :top
    bottom = options.delete :bottom
    before = options.delete :before
    after  = options.delete :after

    wrap_render_html = ''
    wrap_render_html << top if top
    wrap_render_html << (render_html.nil? ? '' : render_html)
    wrap_render_html << bottom if bottom
    html = wrap_render_html
    front = ''
    back = []
    for s in selector
      class_name = []
      tag = 'div'
      id = ''
      s = ".#{s}##{s}" if s.is_a?(Symbol)
      s.scan(/^%\w+|\G[\.|\#]\w+/).each do |ss|
        name = ss.reverse.chop.reverse
        case ss[0,1]
          when '.'; class_name << name
          when '#'; id  = name
          when '%'; tag = name
        end
      end
      attributes = []
      extra_class_names = options.delete :class
      extra_class_names = " #{extra_class_names}"
      options.each{|k,v|attributes << "#{k}='#{v}'"}
      c = class_name.empty? ? extra_class_names : class_name.join(' ')+extra_class_names
      c = "class='#{c}'"
      i = id.blank? ? '' : "id='#{id}'"
      front << "<#{tag} #{c} #{i} #{attributes.join(' ')}>"
      back << "</#{tag}>"
    end
    render_html = front+html+back.reverse.join('')
    html = ''
    html << before if before
    html << render_html
    html << after if after
    html.html_safe
  end

  def partial *args
    options = args.extract_options!
    render_options = {}

    wrap_me = (args.length >= 2 && [Symbol,String,Array].include?(args[0].class) && args[1].is_a?(String))

    empty = options.delete(:empty)

    if wrap_me
      html_options          = (options.key?(:html) ? options[:html] : {})
      html_options[:style]  = options.delete :style
      html_options[:top]    = options.delete :top
      html_options[:bottom] = options.delete :bottom
      html_options[:before] = options.delete :before
      html_options[:after]  = options.delete :after

      selector = args.delete_at(0)
    else
      before = options.delete :before
      after  = options.delete :after
    end

    render_options[:partial] = args[0]
    render_options[:locals] = options
    if args.length >= 2
      render_options[:collection] = args[1]
      render_options[:as] = options.delete :as
    end

    render_html = if render_options.key?(:collection) && render_options[:collection].empty?
      render_options.delete :collection
      empty ? empty : ''
    else
      render render_options
    end

    html = if wrap_me
      wrap selector, render_html, html_options
    else
      html = ''
      html << before if before
      html << (render_html.nil? ? '' : render_html)
      html << after if after
      html
    end
    html.html_safe
  end
end
