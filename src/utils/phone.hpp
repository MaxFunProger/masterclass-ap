#pragma once

#include <optional>
#include <string>
#include <string_view>

namespace masterclasses::utils {

/// Из произвольной строки - 11 цифр, начинается с 7 (например 79261234567).
std::optional<std::string> NormalizeRuPhoneDigits(std::string_view raw);

/// Канонический вид для хранения: +7 и 10 цифр после (без пробелов).
std::optional<std::string> RuPhoneToCanonical(std::string_view raw);

}  // namespace masterclasses::utils
