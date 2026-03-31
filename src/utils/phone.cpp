#include "utils/phone.hpp"

#include <cctype>
#include <string>

namespace masterclasses::utils {

std::optional<std::string> NormalizeRuPhoneDigits(std::string_view raw) {
  std::string digits;
  digits.reserve(16);
  for (char c : raw) {
    if (std::isdigit(static_cast<unsigned char>(c)) != 0) {
      digits.push_back(c);
    }
  }
  if (digits.empty()) {
    return std::nullopt;
  }
  if (digits.size() == 11 && digits[0] == '8') {
    digits[0] = '7';
  }
  if (digits.size() == 10 && digits[0] == '9') {
    digits.insert(digits.begin(), '7');
  }
  if (digits.size() == 11 && digits[0] == '7') {
    return digits;
  }
  return std::nullopt;
}

std::optional<std::string> RuPhoneToCanonical(std::string_view raw) {
  auto d = NormalizeRuPhoneDigits(raw);
  if (!d.has_value()) {
    return std::nullopt;
  }
  return std::string{"+"} + *d;
}

}  // namespace masterclasses::utils
