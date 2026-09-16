# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Public, unauthenticated CSAT feedback endpoint (see docs/DESIGN_FEEDBACK_RATING.md).
# Mirrors the public-controller pattern already used by FormController.
#
# GET  /feedback/:ticket_id?token=...&score=N  -> confirmation page, NO side effects
# POST /feedback/:ticket_id/submit             -> actually saves the score
#
# Split into two steps on purpose: WhatsApp/Telegram generate a link preview
# by fetching the URL server-side before a human ever sees it, and some
# corporate email security gateways do the same. A plain GET must not have
# side effects, or those automated fetches would record fake ratings.
class FeedbackController < ApplicationController
  prepend_before_action -> { authorize! }, only: %i[show submit]

  skip_before_action :verify_csrf_token

  def show
    return render_invalid if !valid_request?

    render html: confirm_page(current_score).html_safe, layout: false
  end

  def submit
    return render_invalid if !valid_request?

    @ticket.update_columns( # rubocop:disable Rails/SkipsModelValidations
      csat_score:         current_score,
      csat_submitted_at:  Time.zone.now,
    )

    render html: thank_you_page.html_safe, layout: false
  end

  private

  def current_score
    params[:score].to_i
  end

  def valid_request?
    return false if current_score < 1 || current_score > 5

    @ticket = Ticket.find_by(id: params[:ticket_id])
    return false if !@ticket

    @token = Token.find_by(action: 'CustomerFeedback', token: params[:token])
    return false if !@token || @token.expired?
    return false if @token.preferences['ticket_id'].to_i != @ticket.id

    true
  end

  def render_invalid
    render html: invalid_page.html_safe, layout: false, status: :not_found
  end

  def page(title, body)
    <<~HTML
      <!doctype html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>#{ERB::Util.html_escape(title)}</title>
          <style>
            body { font-family: sans-serif; text-align: center; padding: 40px 20px; }
            button { font-size: 1.1em; padding: 10px 24px; cursor: pointer; }
          </style>
        </head>
        <body>#{body}</body>
      </html>
    HTML
  end

  def confirm_page(score)
    page('Konfirmasi Rating', <<~HTML)
      <h2>Rating Anda: #{'⭐' * score}#{'☆' * (5 - score)}</h2>
      <p>Klik tombol di bawah untuk mengonfirmasi rating Anda.</p>
      <form method="post" action="/feedback/#{@ticket.id}/submit">
        <input type="hidden" name="token" value="#{ERB::Util.html_escape(params[:token])}">
        <input type="hidden" name="score" value="#{score}">
        <button type="submit">Konfirmasi Kirim</button>
      </form>
    HTML
  end

  def thank_you_page
    page('Terima Kasih', '<h2>Terima kasih atas rating Anda!</h2>')
  end

  def invalid_page
    page('Link Tidak Valid', '<h2>Link ini tidak valid atau sudah kedaluwarsa.</h2>')
  end
end
