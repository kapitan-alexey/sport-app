import SwiftUI
import SafariServices

struct SettingsView: View {
    @State private var showingPrivacyPolicy = false
    
    var body: some View {
        NavigationView {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // App Info Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("О приложении")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 8) {
                                SettingsRow(
                                    icon: "info.circle",
                                    title: "Версия",
                                    value: "1.0"
                                )
                                
                                SettingsRow(
                                    icon: "person.crop.circle",
                                    title: "Разработчик",
                                    value: "Dynamo Team"
                                )
                            }
                        }
                        
                        Divider()
                            .background(Color.gray.opacity(0.3))
                        
                        // Privacy Section
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Конфиденциальность")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            VStack(spacing: 8) {
                                Button(action: {
                                    showingPrivacyPolicy = true
                                }) {
                                    SettingsRowButton(
                                        icon: "hand.raised",
                                        title: "Политика конфиденциальности"
                                    )
                                }
                                .buttonStyle(PlainButtonStyle())
                                
                                SettingsRow(
                                    icon: "chart.bar",
                                    title: "Аналитика",
                                    value: "Включена",
                                    subtitle: "Помогает улучшать приложение"
                                )
                            }
                        }
                        
                        Spacer(minLength: 50)
                        
                        // Footer
                        VStack(spacing: 8) {
                            Text("Dynamo")
                                .font(.custom("HelveticaNeue-Bold", size: 18))
                                .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                            
                            Text("Ваш помощник в мире спорта")
                                .font(.custom("HelveticaNeue", size: 14))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Настройки")
            .navigationBarTitleDisplayMode(.large)
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showingPrivacyPolicy) {
            PrivacySafariView(url: URL(string: "https://kapitan-alexey.github.io/sport-app/docs/privacy-policy.html")!)
        }
    }
}

// MARK: - Settings Row Views

struct SettingsRow: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    
    init(icon: String, title: String, value: String, subtitle: String? = nil) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
    }
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.custom("HelveticaNeue", size: 16))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.custom("HelveticaNeue", size: 12))
                        .foregroundColor(.gray)
                }
            }
            
            Spacer()
            
            Text(value)
                .font(.custom("HelveticaNeue", size: 14))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

struct SettingsRowButton: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(Color(red: 0.0, green: 0.8, blue: 0.7))
                .frame(width: 24)
            
            Text(title)
                .font(.custom("HelveticaNeue", size: 16))
                .foregroundColor(.white)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.gray)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - Privacy Safari View

struct PrivacySafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {
        // No updates needed
    }
}

#Preview {
    SettingsView()
}