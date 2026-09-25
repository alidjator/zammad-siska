class PasswordReset extends App.ControllerFullPage
  # Redesign lupa password SISKA -- Tahap 3 (OTP): username/email -> kode
  # 6 digit -> password baru -> langsung masuk. Link reset di email tetap
  # jalan lewat PasswordResetVerify. Input kode & checklist password dari
  # lib/mixins/siska_auth_otp.coffee (sama dgn layar register).
  @include App.SiskaAuthOtp

  events:
    'submit .js-passwordForm':    'submit'
    'click .retry':               'retry'
    'click .js-changeIdentity':   'retry'
    'submit .js-otpForm':         'verifyOtp'
    'input .js-otpDigit':         'otpInput'
    'keydown .js-otpDigit':       'otpKeydown'
    'paste .js-otpDigit':         'otpPaste'
    'click .js-otpResend':        'resendOtp'
    'submit .js-newPasswordForm': 'submitNewPassword'
    'input [name="password"]':    'updatePasswordRules'
    'click .js-goHome':           'goHome'
  forceRender: true
  className: 'reset_password'

  constructor: ->
    super

    if !@Config.get('user_lost_password')
      @navigate '#'
      return

    if @authenticateCheck()
      @navigate '#'
      return

    @title __('Reset Password')
    @navupdate '#password_reset'

    @publicLinksSubscribeId = App.PublicLink.subscribe(=>
      # Jangan menimpa layar kode / password baru dgn form awal kosong.
      @render() if !@identifier
    )

    @render()

  release: =>
    @clearDelay('siska-otp-cooldown')
    if @publicLinksSubscribeId
      App.PublicLink.unsubscribe(@publicLinksSubscribeId)

  publicLinks: ->
    App.PublicLink.search(
      filter:
        screen: ['password_reset']
      sortBy: 'prio'
    )

  render: (params = {}) ->
    @identifier = undefined
    @resetToken = undefined
    @clearDelay('siska-otp-cooldown')

    configure_attributes = [
      { name: 'username', display: __('Enter your username or email address'), tag: 'input', type: 'text', limit: 100, null: false, class: 'input span4' }
    ]

    params['public_links'] = @publicLinks()

    @replaceWith(App.view('password/reset')(params))

    @form = new App.ControllerForm(
      el:        @el.find('.js-password')
      model:     { configure_attributes: configure_attributes }
      autofocus: true
    )
    @el.find('[name="username"]').attr('autocomplete', 'username')

  retry: (e) ->
    e.preventDefault()
    @render()

  # Langkah 1: minta kode.
  submit: (e) ->
    e.preventDefault()
    params = @formParam(e.target)
    username = String(params.username || '').trim()
    return if !username
    @formDisable(e)

    @requestCode(username,
      done: (data) =>
        @startOtp(username, data)
      fail: =>
        @formEnable(e)
    )

  requestCode: (username, callbacks = {}) ->
    @ajax(
      id:          'siska_auth_password_reset_otp_request'
      type:        'POST'
      url:         "#{@apiPath}/siska_auth/password_reset_otp/request"
      data:        JSON.stringify(username: username)
      processData: true
      success:     (data) => callbacks.done?(data)
      error:       (data) =>
        details = data?.responseJSON || {}
        @notify(
          type: 'error'
          msg:  details.error_human || details.error || __('Loading failed.')
        )
        callbacks.fail?(data)
    )

  # Langkah 2: layar kode. Respons `request` seragam utk akun ada/tidak;
  # `failed` hanya berarti jeda/batas kirim (kode sebelumnya masih bisa
  # dipakai), jadi layar kode tetap ditampilkan.
  startOtp: (username, data = {}) =>
    @identifier   = username
    @otpCooldown  = data.cooldown_seconds || @otpCooldown || 30
    wait          = if data.message is 'ok' then @otpCooldown else (data.wait_seconds || 0)
    @otpCooldownUntil = Date.now() + wait * 1000
    @renderOtp(state: if data.state is 'rate_limited' then 'rate_limited' else null)

  renderOtp: (params = {}) =>
    left = @cooldownLeft()
    @replaceWith App.view('password/reset_otp')(
      identifier:    @identifier
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
      id:          'siska_auth_password_reset_otp_verify'
      type:        'POST'
      url:         "#{@apiPath}/siska_auth/password_reset_otp/verify"
      data:        JSON.stringify(username: @identifier, code: code)
      processData: true
      success: (data) =>
        @otpVerifying = false
        if data.message is 'ok' && data.reset_token
          @resetToken = data.reset_token
          @renderNewPassword()
          return
        @renderOtp(state: data.state, attemptsLeft: data.attempts_left)
      error: =>
        @otpVerifying = false
        @renderOtp(state: 'error')
    )

  resendOtp: (e) =>
    e?.preventDefault()
    return if @cooldownLeft() > 0
    @el.find('.js-otpResend').prop('disabled', true)
    @requestCode(@identifier,
      done: (data) =>
        if data.message is 'ok'
          @otpCooldown      = data.cooldown_seconds || @otpCooldown
          @otpCooldownUntil = Date.now() + @otpCooldown * 1000
          @renderOtp(state: 'resent')
          return
        @otpCooldownUntil = Date.now() + (data.wait_seconds || 0) * 1000 if data.wait_seconds
        @renderOtp(state: if data.state is 'rate_limited' then 'rate_limited' else null)
      fail: =>
        @renderOtp(state: 'error')
    )

  # Langkah 3: password baru.
  renderNewPassword: (error) =>
    @clearDelay('siska-otp-cooldown')
    configure_attributes = [
      { name: 'password',         display: __('New password'),         tag: 'input', type: 'password', limit: 100, null: false, class: 'input' }
      { name: 'password_confirm', display: __('Confirm new password'), tag: 'input', type: 'password', limit: 100, null: false, class: 'input' }
    ]
    @replaceWith(App.view('password/reset_otp_change')(
      public_links: @publicLinks()
    ))
    new App.ControllerForm(
      el:        @el.find('.js-password')
      model:     { configure_attributes: configure_attributes }
      autofocus: true
    )
    @el.find('[name="password"]').attr(placeholder: App.i18n.translatePlain('Create a password'), autocomplete: 'new-password')
    @el.find('[name="password_confirm"]').attr(placeholder: App.i18n.translatePlain('Repeat your password'), autocomplete: 'new-password')
    @renderPasswordRules()
    @showNewPasswordError(error) if error

  showNewPasswordError: (message) =>
    @el.find('.js-alert').html("<div class=\"siska-auth-alert is-danger\" role=\"alert\">#{App.Utils.htmlEscape(message)}</div>")

  submitNewPassword: (e) =>
    e.preventDefault()
    params   = @formParam(e.target)
    password = params.password || ''

    if !password
      @showNewPasswordError(App.i18n.translatePlain('Please provide your new password.'))
      return
    if params.password_confirm isnt password
      @el.find('[name="password"], [name="password_confirm"]').val('')
      @updatePasswordRules()
      @showNewPasswordError(App.i18n.translatePlain("Can't update password, your entered passwords do not match. Please try again."))
      return

    @formDisable(e)
    @ajax(
      id:          'siska_auth_password_reset_otp_complete'
      type:        'POST'
      url:         "#{@apiPath}/siska_auth/password_reset_otp/complete"
      data:        JSON.stringify(reset_token: @resetToken, password: password)
      processData: true
      success: (data) =>
        if data.message is 'ok'
          @passwordChanged(data.logged_in)
          return
        @formEnable(e)
        if data.state is 'password_policy' && _.isArray(data.notice)
          @showNewPasswordError(App.i18n.translatePlain(data.notice[0], data.notice[1]))
        else if data.state is 'invalid_token'
          @replaceWith(App.view('password/reset_failed')(
            head:         __('Reset Password failed!')
            message:      __('Your reset session has expired. Please request a new code.')
            public_links: @publicLinks()
          ))
        else
          @showNewPasswordError(App.i18n.translatePlain('The password could not be set. Please contact your administrator.'))
      error: =>
        @formEnable(e)
        @showNewPasswordError(App.i18n.translatePlain('Could not process your request'))
    )

  # Langkah 4: selesai -- langsung masuk (atau ke login bila akun ber-2FA).
  passwordChanged: (loggedIn) =>
    @resetToken = undefined
    @replaceWith(App.view('password/reset_done')(
      loggedIn:     !!loggedIn
      public_links: @publicLinks()
    ))
    @delay(@goHome, 3000, 'siska-reset-redirect') if loggedIn

  goHome: (e) =>
    e?.preventDefault()
    @clearDelay('siska-reset-redirect')
    App.Auth.loginCheck(=> @navigate '#')

App.Config.set('password_reset', PasswordReset, 'Routes')
