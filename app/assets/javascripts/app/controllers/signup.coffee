class Signup extends App.ControllerFullPage
  # Input kode OTP 6 kotak & checklist password -- lihat lib/mixins/siska_auth_otp.coffee.
  @include App.SiskaAuthOtp

  events:
    # Redesign register SISKA -- Tahap 1: `submit form` dipersempit ke
    # form daftar (`.js-signupForm`) krn layar OTP punya form sendiri.
    'submit .js-signupForm':    'submit'
    'click .submit':            'submit'
    'click .cancel':            'cancel'
    'submit .js-otpForm':       'verifyOtp'
    'input .js-otpDigit':       'otpInput'
    'keydown .js-otpDigit':     'otpKeydown'
    'paste .js-otpDigit':       'otpPaste'
    'click .js-otpResend':      'resendOtp'
    'click .js-goHome':         'goHome'
    'input [name="password"]':  'updatePasswordRules'
  className: 'signup'

  constructor: ->
    super

    # go back if feature is not enabled
    if !@Config.get('user_create_account')
      @navigate '#'
      return

    # set title
    @title __('Sign up')
    @navupdate '#signup'

    @publicLinksSubscribeId = App.PublicLink.subscribe(=>
      # Jangan menimpa layar kode OTP / sukses dgn form daftar kosong.
      @render() if !@otpEmail
    )

    @render()

  release: =>
    if @publicLinksSubscribeId
      App.PublicLink.unsubscribe(@publicLinksSubscribeId)

  publicLinks: ->
    App.PublicLink.search(
      filter:
        screen: ['signup']
      sortBy: 'prio'
    )

  render: ->
    @replaceWith App.view('signup')(
      public_links: @publicLinks()
    )

    @form = new App.ControllerForm(
      el:        @el.find('form')
      model:     App.User
      screen:    'signup'
      autofocus: true
    )

    @applyPlaceholders()
    @renderPasswordRules()

  # Redesign register SISKA -- placeholder utk field form generik
  # (App.ControllerForm tidak diberi placeholder oleh atribut User).
  # Hanya diisi kalau field belum punya placeholder sendiri.
  applyPlaceholders: =>
    placeholders =
      firstname:        __('e.g. Budi')
      lastname:         __('e.g. Santoso')
      email:            'name@example.com'
      password:         __('Create a password')
      password_confirm: __('Repeat your password')
    for name, text of placeholders
      input = @el.find("[name=\"#{name}\"]")
      continue if !input.length || input.attr('placeholder')
      input.attr('placeholder', App.i18n.translatePlain(text))
    @el.find('[name="email"]').attr('autocomplete', 'email')
    @el.find('[name="password"], [name="password_confirm"]').attr('autocomplete', 'new-password')

  cancel: ->
    @navigate '#login'

  submit: (e) =>
    e.preventDefault()
    @formDisable(e)
    @params = @formParam(e.target)

    # if no login is given, use emails as fallback
    if !@params.login && @params.email
      @params.login = @params.email

    @params.signup = true
    @params.role_ids = []
    @log 'debug', 'updateAttributes', @params
    user = new App.User
    user.load(@params)

    errors = user.validate(
      controllerForm: @form
    )

    if errors
      @log 'error new', errors

      # Only highlight, but don't add message. Error text breaks layout.
      Object.keys(errors).forEach (key) ->
        errors[key] = null

      @formValidate(form: e.target, errors: errors)
      @formEnable(e)
      return false
    else
      @formValidate(form: e.target, errors: errors)

    # save user
    user.save(
      done: (r) =>
        # Tahap 1: langsung ke layar kode OTP (bukan lagi "klik link di
        # email"). Aturan (masa berlaku/jeda) dari respons server.
        @startOtp(@params.email, r?.otp || {})
      fail: (settings, details) =>
        @formEnable(e)

        message = if _.isArray(details.notice)
                    App.i18n.translateContent(details.notice[0], details.notice[1])
                  else
                    details.error_human || details.error || __('User could not be created.')

        @form.showAlert(message)
    )

  # ------------------------------------------------------------------
  # Redesign register SISKA -- Tahap 1: layar kode OTP
  # ------------------------------------------------------------------
  startOtp: (email, rules) =>
    @otpEmail     = email
    @otpExpiresIn = rules.expires_in_minutes || 5
    @otpCooldown  = rules.cooldown_seconds || 30
    @otpCooldownUntil = Date.now() + @otpCooldown * 1000
    @renderOtp()

  renderOtp: (params = {}) =>
    left = @cooldownLeft()
    @replaceWith App.view('signup/verify')(
      email:         @otpEmail
      maskedEmail:   @maskEmail(@otpEmail)
      expiresIn:     @otpExpiresIn
      state:         params.state
      attemptsLeft:  params.attemptsLeft
      locked:        params.state in ['expired', 'too_many_attempts']
      cooldown:      left
      cooldownLabel: @cooldownLabel(left)
      public_links:  @publicLinks()
    )
    @el.find('.js-otpDigit').first().trigger('focus') if !(params.state in ['expired', 'too_many_attempts'])
    @tickCooldown()

  verifyOtp: (e) =>
    e?.preventDefault()
    return if @otpVerifying
    code = @otpCode()
    if !/^\d{6}$/.test(code)
      @otpDigits().filter( -> !$(@).val() ).first().trigger('focus')
      return

    @otpVerifying = true
    @el.find('.js-otpSubmit').prop('disabled', true)
    @ajax(
      id:          'siska_auth_signup_otp_verify'
      type:        'POST'
      url:         "#{@apiPath}/siska_auth/signup_otp/verify"
      data:        JSON.stringify(email: @otpEmail, code: code)
      processData: true
      success: (data) =>
        @otpVerifying = false
        if data.message is 'ok'
          @otpVerified()
          return
        @renderOtp(state: data.state, attemptsLeft: data.attempts_left)
      error: =>
        @otpVerifying = false
        @renderOtp(state: 'error')
    )

  otpVerified: =>
    @clearDelay('siska-otp-cooldown')
    @replaceWith App.view('signup/verified')(
      email:        @otpEmail
      public_links: @publicLinks()
    )
    @delay(@goHome, 3000, 'siska-otp-redirect')

  goHome: (e) =>
    e?.preventDefault()
    @clearDelay('siska-otp-redirect')
    App.Auth.loginCheck(=> @navigate '#')

  resendOtp: (e) =>
    e?.preventDefault()
    return if @cooldownLeft() > 0
    @el.find('.js-otpResend').prop('disabled', true)
    @ajax(
      id:          'siska_auth_signup_otp_resend'
      type:        'POST'
      url:         "#{@apiPath}/siska_auth/signup_otp/resend"
      data:        JSON.stringify(email: @otpEmail)
      processData: true
      success: (data) =>
        if data.message is 'ok'
          @otpExpiresIn     = data.expires_in_minutes || @otpExpiresIn
          @otpCooldown      = data.cooldown_seconds || @otpCooldown
          @otpCooldownUntil = Date.now() + @otpCooldown * 1000
          @renderOtp(state: 'resent')
          return
        @otpCooldownUntil = Date.now() + (data.wait_seconds || 0) * 1000 if data.wait_seconds
        @renderOtp(state: if data.state is 'rate_limited' then 'rate_limited' else null)
      error: =>
        @renderOtp(state: 'error')
    )

App.Config.set('signup', Signup, 'Routes')
