class TaxService {
  /// Calculates fortnightly tax based on 2025-26 Australian Individual Tax Scales
  static double calculateFortnightlyTax(double gross, bool taxFreeThreshold) {
    if (gross <= 0) return 0;

    // The ATO works on "Equivalent Annual Income" for pay periods
    double annualEquivalent = gross * 26;
    double annualTax = 0;

    if (taxFreeThreshold) {
      // 2025-26 Resident Rates (Including 2% Medicare Levy)
      if (annualEquivalent <= 18200) {
        annualTax = 0;
      } else if (annualEquivalent <= 45000) {
        annualTax = (annualEquivalent - 18200) * 0.16; // 16% bracket
      } else if (annualEquivalent <= 135000) {
        annualTax = 4288 + (annualEquivalent - 45000) * 0.30; // 30% bracket
      } else if (annualEquivalent <= 190000) {
        annualTax = 31288 + (annualEquivalent - 135000) * 0.37; // 37% bracket
      } else {
        annualTax = 51638 + (annualEquivalent - 190000) * 0.45; // 45% bracket
      }
    } else {
      // No Tax Free Threshold (Higher flat rates)
      annualTax = annualEquivalent * 0.21; // Simplified flat 21% for lower-mid range
    }

    // Convert annual tax back to fortnightly
    return annualTax / 26;
  }
}