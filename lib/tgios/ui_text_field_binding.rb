include SugarCube::CoreGraphics

module Tgios
  class UITextFieldBinding < BindingBase
    include PlasticCup

    def initialize(model, ui_field, field_name, options={})
      super

      Base.add_style_sheet(:decimal_button_common, {
          title: '.',
          titleFont: lambda {UIFont.boldSystemFontOfSize(30)},
      }) unless Base.get_style_sheet(:decimal_button_common)
      Base.add_style_sheet(:decimal_button, {
          extends: :decimal_button_common,
          frame: [[0, 162.5 + 44], [104.5, 54]],
          highlighted_background_image: Tgios::CommonUIUtility.imageFromColor(:white),
          titleColor: :black.uicolor
      }, :ios7) unless Base.get_style_sheet(:decimal_button)

      Base.add_style_sheet(:decimal_button, {
          extends: :decimal_button_common,
          frame: [[0, 163 + 44], [105, 54]],
          highlighted_background_image: Tgios::CommonUIUtility.imageFromColor(UIColor.colorWithRed(0.324, green: 0.352, blue: 0.402, alpha: 1)),
          titleColor: :darkgray.uicolor,
          highlighted_title_color: :white.uicolor
      }) unless Base.get_style_sheet(:decimal_button)

      @field_name=field_name
      @options=options
      @events={}
      @ui_field=WeakRef.new(ui_field)
      @model=WeakRef.new(model)
      update_ui_field_style
      assign_value_to_field
    end

    def assign_value_to_field
      val = @model.send(@field_name)
      if val.is_a?(String) || val.nil?
        @ui_field.text=val
      else
        @original_value = val
        @ui_field.text= if val.respond_to?(:round)
                          default_precision = 0
                          default_precision = 6 unless val.is_a?(Integer)
                          val.round((@options[:precision] || default_precision)).to_s
                        else
                          val.to_s
                        end
        @model.send("#{@field_name}=", @ui_field.text)
      end
    end

    def ui_field=(val)
      @ui_field=WeakRef.new(val)
      @ui_field.delegate=self
      update_ui_field_style
      assign_value_to_field
    end

    def model=(val)
      @model=WeakRef.new(val)
      assign_value_to_field
    end

    def update(ui_field, model)
      self.ui_field=ui_field
      self.model=model

    end

    def on(event, &block)
      @events[event]=block
    end


    def textFieldDidEndEditing(textField)
      puts "textFieldDidEndEditing"
      @model.send("#{@field_name}=", textField.text)
      weak_text_field=WeakRef.new(textField)
      @events[:end_edit].call(@model, @field_name, {text_field: weak_text_field}) unless @events[:end_edit].nil?
      @decimal_button.removeFromSuperview unless @decimal_button.nil?
    end

    def textFieldShouldReturn(textField)
      @ui_field.resignFirstResponder
      weak_text_field=WeakRef.new(@ui_field)
      @events[:return_tapped].call(@model, @field_name, {text_field: weak_text_field}) unless @events[:return_tapped].nil?
    end

    def textFieldDidBeginEditing(textField)
      add_decimal_button
      weak_text_field=WeakRef.new(textField)
      @events[:begin_edit].call(@model, @field_name, {text_field: weak_text_field}) unless @events[:begin_edit].nil?
    end

    def keyboardDidShow(note)
      add_decimal_button if @ui_field.isFirstResponder
    end

    def is_number_pad?
      @ui_field.keyboardType == UIKeyboardTypeNumberPad
    end

    def is_decimal?
      @options[:keyboard] == :decimal && is_number_pad?
    end

    def add_decimal_button
      if is_decimal? && @ui_field.delegate == self
        temp_window = (UIApplication.sharedApplication.windows[1] || UIApplication.sharedApplication.windows[0])
        temp_window.subviews.each do |keyboard|
          if keyboard.description.hasPrefix('<UIPeripheralHost')
            if @decimal_button.nil?
              @decimal_button = PlasticCup::Base.style(UIButton.custom, :decimal_button)
              @decimal_button.addTarget(self, action: 'decimal_tapped', forControlEvents: UIControlEventTouchUpInside)
            end
            keyboard.addSubview(@decimal_button)
            break
          end
        end
      end
    end

    def decimal_tapped
      @ui_field.text = "#{@ui_field.text}." unless !@ui_field.text.nil? && @ui_field.text.include?('.')
    end

    #### options
    # type:
    #   :password
    #   :label
    #
    # auto_correct:
    #   true
    #   false
    #   UITextAutocorrectionType
    #
    # auto_capitalize:
    #   true
    #   false
    #   UITextAutocapitalizationType
    #
    # keyboard:
    #   :decimal
    #   uikeyboardtype (sugarcube)
    #   UIKeyboardType
    #
    # precision: Numeric (only useful when value is Numeric)
    #            default:
    #              Integer: 0
    #              Float:   6
    #
    # error:
    #   true
    #   false
    #
    # reduce_font_size:
    #   true
    #   false
    ####

    def update_ui_field_style
      @ui_field.secureTextEntry=@options[:type]==:password
      @ui_field.autocorrectionType = get_auto_correct_type(@options[:auto_correct])
      @ui_field.autocapitalizationType = get_auto_capitalize_type(@options[:auto_capitalize])
      @ui_field.keyboardType = get_keyboard_type(@options[:keyboard])
      @ui_field.enabled = @options[:type] != :label
      @ui_field.adjustsFontSizeToFitWidth = @options[:reduce_font_size]

      if @model.respond_to?(:has_error?) && @model.has_error?(@field_name)
        @ui_field.leftViewMode = UITextFieldViewModeAlways
        if @ui_field.leftView.nil? || @ui_field.leftView.tag != 888
          error_label_styles ={frame: [[0,0], [25,25]],
                               textColor: :red.uicolor,
                               backgroundColor: :clear.uicolor,
                               font: 'GillSans-Bold'.uifont(25),
                               textAlignment: :center.uialignment,
                               text: '!',
                               tag: 888}
          error_label = PlasticCup::Base.style(UILabel.new, error_label_styles)
          @ui_field.leftView = error_label
        end
      else
        @ui_field.leftViewMode = UITextFieldViewModeNever
      end

      if is_number_pad?
        text_toolbar = PlasticCup::Base.style(UIToolbar.new, frame: CGRectMake(0,0,320,44))
        done_button = UIBarButtonItem.alloc.initWithBarButtonSystemItem(UIBarButtonSystemItemDone, target: self, action: 'textFieldShouldReturn:')
        text_toolbar.items=[
            UIBarButtonItem.flexible_space, done_button
        ]
        @ui_field.inputAccessoryView = text_toolbar
      else
        @ui_field.inputAccessoryView = nil

      end

      stop_listen
      listen_keyboard
    end

    def get_auto_capitalize_type(type=nil)
      case type
        when true, nil
          UITextAutocapitalizationTypeSentences
        when false
          UITextAutocapitalizationTypeNone
        else
          type
      end
    end

    def get_auto_correct_type(type=nil)
      case type
        when true
          UITextAutocorrectionTypeYes
        when false
          UITextAutocorrectionTypeNo
        when nil
          UITextAutocorrectionTypeDefault
        else
          type
      end
    end

    def get_keyboard_type(type=nil)
      return type if type.is_a?(Integer)
      ktype = type == :decimal ? :number : type
      (ktype || :default).uikeyboardtype
    end


    def listen_keyboard
      if is_decimal? && @ui_field.delegate == self
        NSNotificationCenter.defaultCenter.addObserver(self, selector: 'keyboardDidShow:', name: UIKeyboardDidShowNotification, object: nil)
      end

    end

    def stop_listen
      NSNotificationCenter.defaultCenter.removeObserver(self)
    end

    def onPrepareForRelease
      stop_listen
      @model=nil
      @decimal_button=nil
      if !@ui_field.nil? && @ui_field.delegate == self
        @ui_field.delegate = nil
        toolbar = @ui_field.inputAccessoryView
        toolbar.items = nil unless toolbar.nil?
        @ui_field.inputAccessoryView = nil
      end
      @ui_field=nil
      @events=nil
    end

    def dealloc
      prepareForRelease
      ap 'dealloc ui_text_field_binding'
      super
    end

  end
end