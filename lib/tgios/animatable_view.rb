module Tgios
  class AnimatableView < UIView
    DURATION = 0.25

    def initWithFrame(frame)
      super
      bg_view = PlasticCup::Base.style(UIView.new,
                                       frame: self.bounds,
                                       backgroundColor: :white.uicolor,
                                       alpha: 0.95)
      self.addSubview(bg_view)
      self
    end

    def show_animated
      @show_notification ||= NSNotification.notificationWithName(
          UIKeyboardWillShowNotification,
          object: self,
          userInfo:{UIKeyboardFrameEndUserInfoKey=> NSValue.valueWithCGRect(self.frame),
                    UIKeyboardAnimationCurveUserInfoKey=> UIViewAnimationOptionCurveEaseInOut,
                    UIKeyboardAnimationDurationUserInfoKey=> DURATION})
      UIView.animateWithDuration(DURATION, animations: ->{
        NSNotificationCenter.defaultCenter.postNotification(@show_notification)
        self.alpha = 1.0
        frame = self.frame
        frame.origin.y = self.superview.frame.size.height - self.bounds.size.height
        self.frame = frame
      })
      @is_shown = true
    end

    def hide_animated
      if @is_shown
        @hide_notification ||= NSNotification.notificationWithName(
            UIKeyboardWillHideNotification,
            object: self,
            userInfo:{UIKeyboardAnimationCurveUserInfoKey=> UIViewAnimationOptionCurveEaseInOut,
                      UIKeyboardAnimationDurationUserInfoKey=> DURATION})
        UIView.animateWithDuration(DURATION, animations: ->{
          NSNotificationCenter.defaultCenter.postNotification(@hide_notification)
          self.alpha = 0.0
          frame = self.frame
          frame.origin.y = self.superview.frame.size.height
          self.frame = frame
        })
        @is_shown = false
      end
    end
  end
end