import SwiftUI
import StoreKit

struct FeedbackPromptView: View {
    @EnvironmentObject var dataManager: TotsDataManager
    @State private var showingSecondStep = false
    @State private var userIsHappy = false
    @State private var showingThankYou = false
    
    var body: some View {
        ZStack {
            // Background overlay
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    // Don't dismiss on background tap
                }
            
            // Main popup card
            VStack(spacing: 0) {
                if !showingSecondStep && !showingThankYou {
                    // Step 1: Are you enjoying the app?
                    initialFeedbackStep
                } else if showingSecondStep && !showingThankYou {
                    // Step 2: Either rate or give feedback
                    if userIsHappy {
                        happyUserStep
                    } else {
                        unhappyUserStep
                    }
                } else {
                    // Thank you message
                    thankYouStep
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(.white.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.25), radius: 30, x: 0, y: 15)
            .padding(.horizontal, 32)
            .animation(.easeInOut(duration: 0.3), value: showingSecondStep)
            .animation(.easeInOut(duration: 0.3), value: showingThankYou)
        }
    }
    
    private var initialFeedbackStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image("TotsIcon")
                    .resizable()
                    .frame(width: 60, height: 60)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .shadow(color: .black.opacity(0.2), radius: 8, x: 0, y: 4)
                
                VStack(spacing: 8) {
                    Text("How's it going?")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("You've logged 10 activities! 🎉\nAre you enjoying using Tots?")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            
            // Response buttons
            VStack(spacing: 12) {
                Button(action: {
                    userIsHappy = true
                    withAnimation {
                        showingSecondStep = true
                    }
                }) {
                    HStack {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16))
                        Text("Yes, I love it!")
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.green)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    userIsHappy = false
                    withAnimation {
                        showingSecondStep = true
                    }
                }) {
                    HStack {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 16))
                        Text("Not really...")
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.orange)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    dataManager.handleFeedbackPromptResponse(action: .later)
                }) {
                    Text("Ask me later")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.gray.opacity(0.15))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private var happyUserStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "star.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.yellow)
                
                VStack(spacing: 8) {
                    Text("Awesome!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("Would you mind leaving a quick review? It helps other parents discover Tots!")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    // Show App Store rating
                    print("🌟 Attempting to show App Store review prompt...")
                    if let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                        print("✅ Found window scene, calling SKStoreReviewController.requestReview()")
                        SKStoreReviewController.requestReview(in: scene)
                        print("📱 SKStoreReviewController.requestReview() called successfully")
                    } else {
                        print("❌ No window scene found - review prompt cannot be shown")
                    }
                    
                    withAnimation {
                        showingThankYou = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dataManager.handleFeedbackPromptResponse(action: .rated)
                    }
                }) {
                    HStack {
                        Image(systemName: "star.fill")
                            .font(.system(size: 16))
                        Text("Rate on App Store")
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    dataManager.handleFeedbackPromptResponse(action: .later)
                }) {
                    Text("Maybe later")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.gray.opacity(0.15))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private var unhappyUserStep: some View {
        VStack(spacing: 24) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "heart")
                    .font(.system(size: 50))
                    .foregroundColor(.orange)
                
                VStack(spacing: 8) {
                    Text("Help us improve!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text("We'd love to hear your feedback and make Tots better for you and your family.")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                        .lineSpacing(2)
                }
            }
            .padding(.top, 32)
            .padding(.horizontal, 24)
            
            // Action buttons
            VStack(spacing: 12) {
                Button(action: {
                    // Open feedback email
                    if let url = URL(string: "mailto:support@growwithtots.com?subject=Tots%20App%20Feedback&body=Hi%20Tots%20Team,%0A%0AI'd%20like%20to%20share%20some%20feedback%20about%20Tots:%0A%0A") {
                        UIApplication.shared.open(url)
                    }
                    
                    withAnimation {
                        showingThankYou = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        dataManager.handleFeedbackPromptResponse(action: .feedback)
                    }
                }) {
                    HStack {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 16))
                        Text("Send Feedback")
                    }
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(.blue)
                    .cornerRadius(12)
                }
                .buttonStyle(PlainButtonStyle())
                
                Button(action: {
                    dataManager.handleFeedbackPromptResponse(action: .later)
                }) {
                    Text("Maybe later")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(.gray.opacity(0.15))
                        .cornerRadius(8)
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
    
    private var thankYouStep: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
                
                VStack(spacing: 8) {
                    Text("Thank you!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Text(userIsHappy ? "We appreciate your support!" : "Your feedback helps us improve!")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                        .multilineTextAlignment(.center)
                }
            }
            .padding(.vertical, 40)
            .padding(.horizontal, 24)
        }
    }
}

#Preview {
    FeedbackPromptView()
        .environmentObject(TotsDataManager())
}
