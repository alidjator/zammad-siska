# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Enhancement 2 -- Rating Kepuasan (Feedback), direlasikan dgn CSAT
# Fase 1 (docs/DESIGN_FEEDBACK_RATING.md) -- TIDAK ADA tabel/kolom
# baru, tulis LANGSUNG ke `csat_score`/`csat_comment`/
# `csat_submitted_at` milik `Ticket` yang SAMA (Custom Object
# Attribute yang sudah ada), pola `update_columns` MENIRU PERSIS
# `FeedbackController#submit` (jalur async Fase 1 lewat email/WA/
# Telegram) -- widget ini jalur KEDUA yang mengisi field yang SAMA,
# BEDA otorisasi (`Chat::Session` yang sedang berjalan/baru berakhir,
# BUKAN Token terkirim lewat email).
#
# payload
#
#   {
#     event: 'chat_session_feedback_submit',
#     data: {
#       session_id: 'sesi yang baru berakhir (chat biasa ATAU pesan offline)',
#       score: 1..5,
#       comment: 'opsional',
#     },
#   }
#
# return is sent as message back to peer
class Sessions::Event::ChatSessionFeedbackSubmit < Sessions::Event::ChatBase

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session

    ticket = chat_session.ticket
    if !ticket
      return {
        event: 'chat_session_feedback_submit',
        data:  { state: 'failed', message: __('Feedback could not be saved.') },
      }
    end

    score = @payload['data']['score'].to_i
    if !score.between?(1, 5)
      return {
        event: 'chat_session_feedback_submit',
        data:  { state: 'failed', message: __('Please select a rating.') },
      }
    end

    ticket.update_columns( # rubocop:disable Rails/SkipsModelValidations
      csat_score:        score,
      csat_comment:      @payload['data']['comment'].to_s.strip.presence,
      csat_submitted_at: Time.zone.now,
    )

    {
      event: 'chat_session_feedback_submit',
      data:  { state: 'ok' },
    }
  end

end
