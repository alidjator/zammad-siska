# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Public, unauthenticated CSAT feedback endpoint (see docs/DESIGN_FEEDBACK_RATING.md).
# Mirrors the public-controller pattern already used by FormController.
#
# GET  /feedback/:ticket_id?token=...  -> one interactive form (star picker +
#                                          optional comment), NO side effects
# POST /feedback/:ticket_id/submit     -> actually saves score + comment
#
# The customer message (email/Telegram/WhatsApp) only ever contains ONE
# bare link (see Service::Csat::PrepareFeedbackSurveys#render_template and
# script/create_csat_email_trigger.rb) -- picking a star and writing a
# comment both happen on this one page, submitted together.
#
# Split into GET (render only) / POST (write) on purpose: WhatsApp/Telegram
# generate a link preview by fetching the URL server-side before a human
# ever sees it, and some corporate email security gateways do the same. A
# plain GET must not have side effects, or those automated fetches would
# record fake ratings.
class FeedbackController < ApplicationController
  prepend_before_action -> { authorize! }, only: %i[show submit]

  skip_before_action :verify_csrf_token

  def show
    return render_invalid if !valid_token?

    render html: form_page.html_safe, layout: false
  end

  def submit
    return render_invalid if !valid_token?
    return render_invalid if !valid_score?

    @ticket.update_columns( # rubocop:disable Rails/SkipsModelValidations
      csat_score:         current_score,
      csat_comment:       params[:comment].to_s.strip.presence,
      csat_submitted_at:  Time.zone.now,
    )

    render html: thank_you_page.html_safe, layout: false
  end

  private

  def current_score
    params[:score].to_i
  end

  def valid_score?
    current_score.between?(1, 5)
  end

  def valid_token?
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

  # Colors/spacing below are taken directly from Zammad's own agent-app
  # form styling (app/assets/stylesheets/zammad.scss's :root variables and
  # .label/input/.btn--primary rules), hardcoded as plain hex since this
  # page is served standalone (no Rails layout, no runtime CSS-variable
  # cascade from the app shell) -- not a guess, and not the same palette
  # as public/assets/error/style.css (which is a different, more generic
  # "standalone page" reference; this one specifically mirrors the New
  # Ticket-style form: uppercase gray labels, white card, blue primary
  # button) per the user's screenshot request.
  def page(title, body)
    <<~HTML
      <!doctype html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>#{ERB::Util.html_escape(title)}</title>
          <style>
            body {
              font-family: 'Fira Sans', 'Helvetica Neue', Helvetica, Arial, sans-serif;
              background: #f7f9fa;
              color: #57574f;
              margin: 0;
              padding: 40px 16px;
              display: flex;
              justify-content: center;
            }
            .csat-card {
              width: 100%;
              max-width: 440px;
              background: #fff;
              border: 1px solid #e5e5e5;
              border-radius: 6px;
              box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06);
              padding: 32px 28px;
              box-sizing: border-box;
              text-align: center;
            }
            .csat-logo { height: 40px; margin-bottom: 20px; }
            blockquote {
              margin: 8px 0 24px;
              padding: 1px 12px;
              border-left: 5px solid #edf1f2;
              text-align: start;
              color: #8c959c;
              font-size: 14px;
            }
            h1 {
              font-size: 22px;
              font-weight: normal;
              margin: 0 0 8px;
              color: #444;
            }
            .subtitle { color: #a3a6a8; font-size: 14px; margin: 0 0 24px; }

            .form-group { margin-bottom: 20px; text-align: start; }
            .form-group label {
              display: block;
              text-transform: uppercase;
              color: #a3a6a8;
              font-size: 13px;
              font-weight: normal;
              letter-spacing: 0.05em;
              margin-bottom: 6px;
            }

            .star-rating {
              display: flex;
              flex-direction: row-reverse;
              justify-content: center;
              gap: 4px;
            }
            .star-rating input { display: none; }
            .star-rating label {
              text-transform: none;
              letter-spacing: 0;
              font-size: 2.4em;
              line-height: 1;
              color: #e5e5e5;
              cursor: pointer;
              transition: color .1s;
            }
            .star-rating label:hover,
            .star-rating label:hover ~ label,
            .star-rating input:checked ~ label {
              color: #4caee1;
            }

            textarea {
              display: block;
              width: 100%;
              box-sizing: border-box;
              font-family: inherit;
              font-size: 14px;
              color: #57574f;
              padding: 7px 12px;
              background: #fff;
              border: 1px solid #e5e5e5;
              border-radius: 3px;
              resize: vertical;
            }
            textarea:focus {
              outline: none;
              border-color: #4caee1;
              box-shadow: 0 0 0 3px #d6eaf5;
            }

            button {
              display: inline-block;
              font-size: 14px;
              padding: 10px 28px 9px;
              margin-top: 4px;
              cursor: pointer;
              color: #fff;
              background: #429ed7;
              border: none;
              border-radius: 4px;
            }
            button:hover { background: #2884bd; }
          </style>
        </head>
        <body>#{body}</body>
      </html>
    HTML
  end

  def form_page
    page('Beri Rating', <<~HTML)
      <div class="csat-card">
        <img class="csat-logo" src="/api/v1/system_assets/product_logo/#{ERB::Util.url_encode(Setting.get('product_logo'))}" alt="#{ERB::Util.html_escape(Setting.get('product_name'))}">
        <h1>Bagaimana pengalaman Anda dengan layanan kami?</h1>
        <p class="subtitle">Ticket ##{@ticket.number}</p>
        #{original_complaint_blockquote}
        <form method="post" action="/feedback/#{@ticket.id}/submit">
          <input type="hidden" name="token" value="#{ERB::Util.html_escape(params[:token])}">
          <div class="form-group">
            <label>Rating</label>
            <div class="star-rating">
              #{(1..5).to_a.reverse.map { |score| star_input(score) }.join}
            </div>
          </div>
          <div class="form-group">
            <label>Komentar (opsional)</label>
            <textarea name="comment" rows="4" placeholder="Tulis komentar Anda di sini..."></textarea>
          </div>
          <button type="submit">Kirim</button>
        </form>
      </div>
    HTML
  end

  # Reminds the customer WHAT they're rating -- their own original message,
  # not just a ticket number -- styled like Zammad's own native quote
  # block (border-left: 5px solid var(--background-primary-alt), padding
  # 1px 12px -- see .richtext-content blockquote in zammad.scss).
  def original_complaint_blockquote
    article = @ticket.articles.reorder(created_at: :asc).first
    return '' if article.blank?

    text = ActionView::Base.full_sanitizer.sanitize(article.body.to_s).squish.truncate(240)
    return '' if text.blank?

    "<blockquote>#{ERB::Util.html_escape(text)}</blockquote>"
  end

  def star_input(score)
    <<~HTML
      <input type="radio" id="star#{score}" name="score" value="#{score}" required>
      <label for="star#{score}" title="#{score}">★</label>
    HTML
  end

  def thank_you_page
    page('Terima Kasih', '<h2>Terima kasih atas rating Anda!</h2>')
  end

  def invalid_page
    page('Link Tidak Valid', '<h2>Link ini tidak valid atau sudah kedaluwarsa.</h2>')
  end
end
