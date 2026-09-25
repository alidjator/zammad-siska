# Redesign login/register SISKA -- perilaku bersama layar kode OTP 6 kotak
# & checklist aturan password halaman auth. Dipakai Signup (Tahap 1, OTP
# register) & PasswordReset (Tahap 3, OTP lupa password). Controller
# pemakai menyediakan `@otpCooldownUntil` (ms epoch) & markup
# `.js-otpDigit` / `.js-otpForm` / `.js-otpResend`, dan mendaftarkan
# event `input/keydown/paste .js-otpDigit` ke otpInput/otpKeydown/otpPaste.
App.SiskaAuthOtp =
  maskEmail: (email) ->
    [local, domain] = String(email || '').split('@')
    return email if !domain
    masked = if local.length <= 4 then "#{local[0] || ''}***" else "#{local.slice(0, 2)}****#{local.slice(-2)}"
    "#{masked}@#{domain}"

  cooldownLeft: ->
    Math.max(0, Math.ceil(((@otpCooldownUntil || 0) - Date.now()) / 1000))

  cooldownLabel: (seconds) ->
    "#{Math.floor(seconds / 60)}:#{String(seconds % 60).padStart(2, '0')}"

  # Teks "Resend code in m:ss" diperbarui tiap detik (textContent).
  tickCooldown: ->
    @clearDelay('siska-otp-cooldown')
    left   = @cooldownLeft()
    button = @el.find('.js-otpResend')
    if left <= 0
      button.prop('disabled', false).text(App.i18n.translatePlain('Resend code'))
      return
    button.prop('disabled', true).text(App.i18n.translatePlain('Resend code in %s', @cooldownLabel(left)))
    @delay((=> @tickCooldown()), 1000, 'siska-otp-cooldown')

  otpDigits: ->
    @el.find('.js-otpDigit')

  otpCode: ->
    (@otpDigits().map( -> $(@).val() ).get()).join('')

  fillOtp: (value, startIndex = 0) ->
    digits = String(value || '').replace(/\D/g, '').split('')
    inputs = @otpDigits()
    index  = startIndex
    for digit in digits
      break if index >= inputs.length
      inputs.eq(index).val(digit)
      index += 1
    inputs.eq(Math.min(index, inputs.length - 1)).trigger('focus')
    @submitOtpIfComplete()

  otpInput: (e) ->
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

  otpKeydown: (e) ->
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

  otpPaste: (e) ->
    text = (e.originalEvent || e).clipboardData?.getData('text') || ''
    return if !text
    e.preventDefault()
    @fillOtp(text, @otpDigits().index($(e.currentTarget)))

  submitOtpIfComplete: ->
    @el.find('.js-otpForm').trigger('submit') if /^\d{6}$/.test(@otpCode())

  # Checklist aturan password di bawah field `[name="password"]`
  # (GET /siska_auth/password_policy -- setting kebijakan password tidak
  # ada di App.Config sebelum login). Validasi tetap di server.
  renderPasswordRules: ->
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

  updatePasswordRules: ->
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
