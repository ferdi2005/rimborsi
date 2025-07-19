module ExpensesHelper
  # Determina l'icona da mostrare per il tipo di file
  def file_icon(expense)
    return "fas fa-car" if expense.car?
    return "fas fa-file-invoice" if expense.electronic_invoice? && expense.has_invoice_pdf?

    return "fas fa-file-pdf" if expense.attachment.attached? && expense.attachment.content_type == "application/pdf"
    return "fas fa-file-image" if expense.attachment.attached? && expense.attachment.content_type.start_with?("image/")

    "fas fa-file"
  end

  # Determina il colore del badge per il tipo di file
  def file_badge_class(expense)
    return "bg-info" if expense.car?
    return "bg-success" if expense.electronic_invoice? && expense.has_invoice_pdf?
    return "bg-danger" if expense.attachment.attached? && expense.attachment.content_type == "application/pdf"
    return "bg-primary" if expense.attachment.attached? && expense.attachment.content_type.start_with?("image/")
    return "bg-warning" if expense.attachment.attached? && (expense.attachment.content_type.include?("xml") || expense.attachment.filename.to_s.downcase.include?(".xml"))

    "bg-secondary"
  end

  # Determina il testo del badge per il tipo di file
  def file_type_text(expense)
    return "Rimborso chilometrico" if expense.car?
    return "Fattura elettronica" if expense.electronic_invoice? && expense.has_invoice_pdf?
    return "PDF" if expense.attachment.attached? && expense.attachment.content_type == "application/pdf"
    return "Immagine" if expense.attachment.attached? && expense.attachment.content_type.start_with?("image/")

    "File"
  end
end
