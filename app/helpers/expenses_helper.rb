module ExpensesHelper
  # Determina l'icona da mostrare per il tipo di file
  def file_icon(expense)
    return "fas fa-car" if expense.car?
    return "fas fa-file-invoice" if expense.electronic_invoice? && expense.has_invoice_pdf?

    # Per allegati multipli, usa l'icona del primo allegato
    if expense.attachments.any?
      first_attachment = expense.attachments.first
      return "fas fa-file-pdf" if first_attachment.content_type == "application/pdf"
      return "fas fa-file-image" if first_attachment.content_type.start_with?("image/")
    end

    "fas fa-file"
  end

  # Determina il colore del badge per il tipo di file
  def file_badge_class(expense)
    return "bg-info" if expense.car?
    return "bg-success" if expense.electronic_invoice? && expense.has_invoice_pdf?

    # Per allegati multipli, usa il badge del primo allegato
    if expense.attachments.any?
      first_attachment = expense.attachments.first
      return "bg-danger" if first_attachment.content_type == "application/pdf"
      return "bg-primary" if first_attachment.content_type.start_with?("image/")
      return "bg-warning" if first_attachment.content_type.include?("xml") || first_attachment.filename.to_s.downcase.include?(".xml")
    end

    "bg-secondary"
  end

  # Determina il testo del badge per il tipo di file
  def file_type_text(expense)
    return "Rimborso chilometrico" if expense.car?
    return "Fattura elettronica" if expense.electronic_invoice? && expense.has_invoice_pdf?

    # Per allegati multipli, mostra il conteggio
    if expense.attachments.any?
      return "#{expense.attachments.count} allegati" if expense.attachments.count > 1

      first_attachment = expense.attachments.first
      return "PDF" if first_attachment.content_type == "application/pdf"
      return "Immagine" if first_attachment.content_type.start_with?("image/")
    end

    "File"
  end
end
