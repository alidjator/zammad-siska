class Signup extends App.ControllerFullPage
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
  # Redesign register SISKA -- Tahap 1: checklist aturan password
  # (GET /siska_auth/password_policy -- setting kebijakan password
  # tidak ada di App.Config sebelum login). Validasi tetap di server.
  # ------------------------------------------------------------------
  renderPasswordRules: =>
    @ajax(
      id:    'siska_auth_password_policy'
      type:  'GET'
      url:   "#{@apiPath}/siska_auth/password_policy"
      success: (policy) =>
        @passwordPolicy = policy
        field = @el.find('[name="password"]').first().closest('.form-group')
        return if !field.length
        @el.find('.js-passwordRules').remove()
        field.after(App.view('signup/password_rules')(rules: @passwordRuleList(policy)))
        @updatePasswordRules()
    )

  passwordRuleList: (policy) ->
    rules = []
    rules.push(key: 'length',  label: App.i18n.translatePlain('At least %s characters', policy.min_size)) if policy.min_size > 0
    rules.push(key: 'digit',   label: App.i18n.translatePlain('Contains a number')) if policy.need_digit
    rules.push(key: 'case',    label: App.i18n.translatePlain('2 lowercase & 2 uppercase letters')) if policy.need_lower_upper
    rules.push(key: 'special', label: App.i18n.translatePlain('Contains a special character')) if policy.need_special_character
    rules

  updatePasswordRules: =>
    policy = @passwordPolicy
    return if !policy
    value = @el.find('[name="password"]').first().val() || ''
    passed =
      length:  value.length >= policy.min_size
      digit:   /\d/.test(value)
      case:    (value.match(/[a-z]/g) || []).length >= 2 && (value.match(/[A-Z]/g) || []).length >= 2
      special: /[^A-Za-z0-9]/.test(value)
    @el.find('.js-passwordRule').each( ->
      $(@).toggleClass('is-ok', !!passed[$(@).data('rule')])
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

  maskEmail: (email) ->
    [local, domain] = String(email || '').split('@')
    return email if !domain
    masked = if local.length <= 4 then "#{local[0] || ''}***" else "#{local.slice(0, 2)}****#{local.slice(-2)}"
    "#{masked}@#{domain}"

  cooldownLeft: =>
    Math.max(0, Math.ceil(((@otpCooldownUntil || 0) - Date.now()) / 1000))

  cooldownLabel: (seconds) ->
    "#{Math.floor(seconds / 60)}:#{String(seconds % 60).padStart(2, '0')}"

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

  tickCooldown: =>
    @clearDelay('siska-otp-cooldown')
    left   = @cooldownLeft()
    button = @el.find('.js-otpResend')
    if left <= 0
      button.prop('disabled', false).text(App.i18n.translatePlain('Resend code'))
      return
    button.prop('disabled', true).text(App.i18n.translatePlain('Resend code in %s', @cooldownLabel(left)))
    @delay(@tickCooldown, 1000, 'siska-otp-cooldown')

  otpDigits: =>
    @el.find('.js-otpDigit')

  otpCode: =>
    (@otpDigits().map( -> $(@).val() ).get()).join('')

  fillOtp: (value, startIndex = 0) =>
    digits = String(value || '').replace(/\D/g, '').split('')
    inputs = @otpDigits()
    index  = startIndex
    for digit in digits
      break if index >= inputs.length
      inputs.eq(index).val(digit)
      index += 1
    inputs.eq(Math.min(index, inputs.length - 1)).trigger('focus')
    @submitOtpIfComplete()

  otpInput: (e) =>
    input = $(e.currentTarget)
    value = input.val().replace(/\D/g, '')
    index = @otpDigits().index(input)
    if value.length > 1
      # Autofill browser/OS (one-time-code) bisa mengisi semua digit
      # sekaligus ke kotak pertama -- sebar ke kotak berikutnya.
      input.val('')
      @fillOtp(value, index)
      return
    input.val(value)
    @otpDigits().eq(index + 1).trigger('focus') if value
    @submitOtpIfComplete()

  otpKeydown: (e) =>
    input = $(e.currentTarget)
    index = @otpDigits().index(input)
    if e.key is 'Backspace' && !input.val() && index > 0
      e.preventDefault()
      @otpDigits().eq(index - 1).val('').trigger('focus')
    else if e.key is 'ArrowLeft' && index > 0
      e.preventDefault()
      @otpDigits().eq(index - 1).trigger('focus')
    else if e.key is 'ArrowRight'
      e.preventDefault()
      @otpDigits().eq(index + 1).trigger('focus')

  otpPaste: (e) =>
    text = (e.originalEvent || e).clipboardData?.getData('text') || ''
    return if !text
    e.preventDefault()
    @fillOtp(text, @otpDigits().index($(e.currentTarget)))

  submitOtpIfComplete: =>
    @el.find('.js-otpForm').trigger('submit') if /^\d{6}$/.test(@otpCode())

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
