import SwiftUI

struct AppIconView: View {
    var size: CGFloat = 200
    
    var body: some View {
        ZStack {
            // Fundalul - Gradientul de la zi la noapte
            LinearGradient(
                colors: [Color.indigo, Color.orange, Color.yellow],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Cercul Biologic (Ritmul Circadian)
            Circle()
                .stroke(Color.white.opacity(0.2), lineWidth: size * 0.05)
                .frame(width: size * 0.8, height: size * 0.8)
            
            // Simbolul Soarelui / Golden Hour
            VStack(spacing: 0) {
                Image(systemName: "sun.horizon.fill")
                    .font(.system(size: size * 0.4, weight: .bold))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
            }
            
            // Detaliu Biohacking (Punctul de Focus)
            Circle()
                .fill(Color.white)
                .frame(width: size * 0.04, height: size * 0.04)
                .offset(x: size * 0.35 * cos(.pi / 4), y: size * 0.35 * sin(.pi / 4))
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: size * 0.22, style: .continuous)) // Forma standard iOS
    }
}

#Preview {
    AppIconView(size: 200)
        .padding()
}
