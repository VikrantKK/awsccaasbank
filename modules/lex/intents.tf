################################################################################
# Lex V2 Intents — Westpac IVR Self-Service
################################################################################

# ---------------------------------------------------------------------------
# CheckBalance — Account balance enquiry
# ---------------------------------------------------------------------------
resource "aws_lexv2models_intent" "check_balance" {
  bot_id      = aws_lexv2models_bot.self_service.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.en_au.locale_id
  name        = "CheckBalance"
  description = "Customer requests their account balance"

  sample_utterance {
    utterance = "I want to check my balance"
  }

  sample_utterance {
    utterance = "What's my account balance"
  }

  sample_utterance {
    utterance = "Check my balance"
  }

  sample_utterance {
    utterance = "How much is in my account"
  }

  sample_utterance {
    utterance = "Show me my balance"
  }

  closing_setting {
    active = true

    closing_response {
      message_group {
        message {
          plain_text_message {
            value = "Let me look up your account balance for you now."
          }
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# ReportLostCard — Lost or stolen card reporting
# ---------------------------------------------------------------------------
resource "aws_lexv2models_intent" "report_lost_card" {
  bot_id      = aws_lexv2models_bot.self_service.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.en_au.locale_id
  name        = "ReportLostCard"
  description = "Customer reports a lost or stolen card"

  sample_utterance {
    utterance = "I lost my card"
  }

  sample_utterance {
    utterance = "My card was stolen"
  }

  sample_utterance {
    utterance = "Report lost card"
  }

  sample_utterance {
    utterance = "I need to cancel my card"
  }

  sample_utterance {
    utterance = "My card is missing"
  }

  closing_setting {
    active = true

    closing_response {
      message_group {
        message {
          plain_text_message {
            value = "I'll help you report your card as lost or stolen. Let me connect you to our card services team to secure your account immediately."
          }
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# BranchHours — Branch operating hours enquiry
# ---------------------------------------------------------------------------
resource "aws_lexv2models_intent" "branch_hours" {
  bot_id      = aws_lexv2models_bot.self_service.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.en_au.locale_id
  name        = "BranchHours"
  description = "Customer asks about branch opening hours"

  sample_utterance {
    utterance = "What are your branch hours"
  }

  sample_utterance {
    utterance = "When do you open"
  }

  sample_utterance {
    utterance = "What time does the branch close"
  }

  sample_utterance {
    utterance = "Are you open on weekends"
  }

  sample_utterance {
    utterance = "Branch opening times"
  }

  closing_setting {
    active = true

    closing_response {
      message_group {
        message {
          plain_text_message {
            value = "Westpac branches are generally open Monday to Friday, 9:30 AM to 4:00 PM. Some branches offer extended hours. Visit westpac.com.au/locateus for your nearest branch details."
          }
        }
      }
    }
  }
}

# ---------------------------------------------------------------------------
# FallbackIntent — Built-in fallback, directs customer to a live agent
# ---------------------------------------------------------------------------
resource "aws_lexv2models_intent" "fallback" {
  bot_id      = aws_lexv2models_bot.self_service.id
  bot_version = "DRAFT"
  locale_id   = aws_lexv2models_bot_locale.en_au.locale_id
  name        = "FallbackIntent"
  description = "Built-in fallback intent — transfers to a live agent"

  parent_intent_signature = "AMAZON.FallbackIntent"

  closing_setting {
    active = true

    closing_response {
      message_group {
        message {
          plain_text_message {
            value = "I'm sorry, I wasn't able to understand your request. Let me transfer you to one of our customer service representatives who can help you further."
          }
        }
      }
    }
  }
}
