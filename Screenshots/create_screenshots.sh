#!/bin/bash

# Скрипт для создания скриншотов App Store для приложения Dynamo

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функция для вывода цветного текста
print_color() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

print_color $BLUE "🚀 Создание скриншотов для App Store - Dynamo"
echo

# Проверяем, что мы в правильной директории
if [ ! -f "../SportApp/SportApp.xcodeproj/project.pbxproj" ]; then
    print_color $RED "❌ Ошибка: Не найден файл проекта SportApp.xcodeproj"
    print_color $YELLOW "Убедитесь, что вы находитесь в папке Screenshots проекта"
    exit 1
fi

# Создаем папки для скриншотов
mkdir -p iPhone_6.7_inch
mkdir -p iPhone_6.5_inch
mkdir -p iPhone_6.1_inch

print_color $GREEN "📁 Созданы папки для скриншотов"

# Устройства для скриншотов
declare -A DEVICES
DEVICES["iPhone_6.7"]="iPhone 16 Pro Max"
DEVICES["iPhone_6.5"]="iPhone 15 Plus" 
DEVICES["iPhone_6.1"]="iPhone 15"

# Функция для запуска симулятора
boot_simulator() {
    local device_name="$1"
    print_color $YELLOW "⚡ Запуск симулятора: $device_name"
    
    # Завершаем все симуляторы
    xcrun simctl shutdown all 2>/dev/null
    sleep 2
    
    # Запускаем нужный симулятор
    xcrun simctl boot "$device_name" 2>/dev/null
    if [ $? -eq 0 ]; then
        print_color $GREEN "✅ Симулятор '$device_name' запущен"
    else
        print_color $RED "❌ Ошибка запуска симулятора '$device_name'"
        return 1
    fi
    
    # Ждем полной загрузки
    sleep 5
    
    # Открываем Simulator.app если он не открыт
    open -a Simulator 2>/dev/null
    sleep 2
}

# Функция для сборки и запуска приложения
build_and_run() {
    local device_name="$1"
    print_color $YELLOW "🔨 Сборка приложения для $device_name..."
    
    cd ../SportApp
    
    # Собираем приложение
    xcodebuild -project SportApp.xcodeproj \
               -scheme SportApp \
               -destination "platform=iOS Simulator,name=$device_name" \
               -configuration Debug \
               build > /dev/null 2>&1
    
    if [ $? -eq 0 ]; then
        print_color $GREEN "✅ Приложение собрано успешно"
    else
        print_color $RED "❌ Ошибка сборки приложения"
        cd ../Screenshots
        return 1
    fi
    
    # Запускаем приложение
    xcrun simctl launch "$device_name" com.dynamoapp.dynamo > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        print_color $GREEN "✅ Приложение запущено"
    else
        print_color $RED "❌ Ошибка запуска приложения"
        cd ../Screenshots
        return 1
    fi
    
    cd ../Screenshots
    
    # Даем время приложению загрузиться
    sleep 8
}

# Функция для создания скриншота
take_screenshot() {
    local device_key="$1"
    local screen_name="$2"
    local description="$3"
    
    print_color $BLUE "📸 Скриншот: $description"
    
    # Создаем скриншот
    xcrun simctl io booted screenshot "${device_key}_inch/${screen_name}_${device_key}.png"
    
    if [ -f "${device_key}_inch/${screen_name}_${device_key}.png" ]; then
        print_color $GREEN "✅ Скриншот сохранен: ${screen_name}_${device_key}.png"
    else
        print_color $RED "❌ Ошибка создания скриншота"
    fi
    
    sleep 2
}

# Функция для создания скриншотов для одного устройства
create_screenshots_for_device() {
    local device_key="$1"
    local device_name="${DEVICES[$device_key]}"
    
    print_color $BLUE "📱 Создание скриншотов для $device_name ($device_key)"
    echo
    
    # Запускаем симулятор
    if ! boot_simulator "$device_name"; then
        return 1
    fi
    
    # Собираем и запускаем приложение
    if ! build_and_run "$device_name"; then
        return 1
    fi
    
    print_color $YELLOW "Теперь вам нужно вручную создать скриншоты:"
    print_color $BLUE "1. Дождитесь полной загрузки приложения"
    print_color $BLUE "2. Создайте скриншоты основных экранов:"
    print_color $BLUE "   - Главный экран со списком событий"
    print_color $BLUE "   - Экран с фильтрами (откройте меню фильтров)"
    print_color $BLUE "   - Детальный экран события (откройте любое событие)"
    print_color $BLUE "   - Дополнительные экраны (настройки, карта и т.д.)"
    print_color $BLUE "3. Для создания скриншота нажмите Cmd+S в симуляторе"
    print_color $BLUE "4. Переместите скриншоты в папку ${device_key}_inch/"
    
    print_color $YELLOW "Нажмите любую клавишу, когда закончите создание скриншотов..."
    read -n 1 -s
    echo
}

# Главная функция
main() {
    print_color $GREEN "Начинаем создание скриншотов для всех размеров экранов"
    echo
    
    # Создаем скриншоты для каждого размера экрана
    for device_key in "iPhone_6.7" "iPhone_6.5"; do
        create_screenshots_for_device "$device_key"
        echo
    done
    
    # Завершаем все симуляторы
    xcrun simctl shutdown all 2>/dev/null
    
    print_color $GREEN "🎉 Создание скриншотов завершено!"
    print_color $BLUE "📁 Проверьте папки iPhone_6.7_inch/ и iPhone_6.5_inch/"
    
    echo
    print_color $YELLOW "Следующие шаги:"
    print_color $BLUE "1. Переименуйте скриншоты по схеме:"
    print_color $BLUE "   01_main_screen_6.7.png"
    print_color $BLUE "   02_filters_6.7.png"
    print_color $BLUE "   03_event_detail_6.7.png"
    print_color $BLUE "   04_settings_6.7.png"
    print_color $BLUE "   05_additional_6.7.png"
    print_color $BLUE "2. Загрузите их в App Store Connect"
    print_color $BLUE "3. Обязательно загрузите скриншоты для 6.7\" и 6.5\""
}

# Запускаем основную функцию
main