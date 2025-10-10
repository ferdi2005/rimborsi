module StatusHelper
  def status_badge(status, type = :reimboursement)
    case type
    when :reimboursement
      reimboursement_status_badge(status)
    when :expense
      expense_status_badge(status)
    when :payment
      payment_status_badge(status)
    else
      generic_status_badge(status)
    end
  end

  private

  def reimboursement_status_badge(status)
    config = reimboursement_status_config[status] || default_status_config
    render_status_badge(config[:text], config[:class], config[:icon])
  end

  def expense_status_badge(status)
    config = expense_status_config[status] || default_status_config
    render_status_badge(config[:text], config[:class], config[:icon])
  end

  def payment_status_badge(status)
    config = payment_status_config[status] || default_status_config
    render_status_badge(config[:text], config[:class], config[:icon])
  end

  def render_status_badge(text, css_class, icon)
    content_tag :span, class: "status-badge #{css_class}" do
      concat content_tag(:i, "", class: "fas fa-#{icon} me-1") if icon
      concat text
    end
  end

  def reimboursement_status_config
    {
      "created" => {
        text: "In attesa di elaborazione",
        class: "status-pending",
        icon: "hourglass-half"
      },
      "in_process" => {
        text: "In elaborazione",
        class: "status-processing",
        icon: "spinner"
      },
      "approved" => {
        text: "Approvato",
        class: "status-approved",
        icon: "check-circle"
      },
      "paid" => {
        text: "Pagato",
        class: "status-paid",
        icon: "credit-card"
      },
      "waiting" => {
        text: "In attesa dell'utente",
        class: "status-waiting",
        icon: "pause-circle"
      }
    }
  end

  def expense_status_config
    {
      "created" => {
        text: "In attesa di approvazione",
        class: "status-pending",
        icon: "hourglass-half"
      },
      "approved" => {
        text: "Approvata",
        class: "status-approved",
        icon: "check-circle"
      },
      "denied" => {
        text: "Negata",
        class: "status-denied",
        icon: "times-circle"
      }
    }
  end

  def payment_status_config
    {
      "created" => {
        text: "In attesa di elaborazione",
        class: "status-pending",
        icon: "hourglass-half"
      },
      "paid" => {
        text: "Pagato",
        class: "status-paid",
        icon: "credit-card"
      },
      "error" => {
        text: "Errore",
        class: "status-error",
        icon: "exclamation-triangle"
      }
    }
  end

  def default_status_config
    { text: "Sconosciuto", class: "status-unknown", icon: "question-circle" }
  end

  def generic_status_badge(status)
    render_status_badge(status.humanize, "status-generic", nil)
  end

  # Helper for normalized info icons
  def info_icon(icon_name, css_class = "icon-neutral", options = {})
    additional_class = options[:class] || ""
    content_tag :i, "", class: "fas fa-#{icon_name} info-icon #{css_class} #{additional_class}".strip
  end

  def primary_icon(icon_name, options = {})
    info_icon(icon_name, "icon-primary", options)
  end

  def secondary_icon(icon_name, options = {})
    info_icon(icon_name, "icon-secondary", options)
  end

  def success_icon(icon_name, options = {})
    info_icon(icon_name, "icon-success", options)
  end

  def warning_icon(icon_name, options = {})
    info_icon(icon_name, "icon-warning", options)
  end

  def danger_icon(icon_name, options = {})
    info_icon(icon_name, "icon-danger", options)
  end

  def neutral_icon(icon_name, options = {})
    info_icon(icon_name, "icon-neutral", options)
  end

  def muted_icon(icon_name, options = {})
    info_icon(icon_name, "icon-muted", options)
  end

  # Helper per badge attivo/inattivo generici
  def active_badge(is_active, active_text: "Attivo", inactive_text: "Inattivo", css_class: "")
    badge_class = "badge #{css_class}".strip

    if is_active
      content_tag :span, class: "#{badge_class} bg-success" do
        concat success_icon("check", class: "me-1")
        concat active_text
      end
    else
      content_tag :span, class: "#{badge_class} bg-secondary" do
        concat secondary_icon("times", class: "me-1")
        concat inactive_text
      end
    end
  end
end
