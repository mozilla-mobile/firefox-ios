// MicrosurveyAlert.swift

import SwiftUI

/// Microsurvey alert view
struct MicrosurveyAlert: View {
    var body: some View {
        VStack(alignment: .leading) {
            Text("Take our microsurvey")
                .font(.headline)
                .padding(.bottom, 4)
            Text("We want to hear from you!")
                .font(.body)
                .padding(.bottom, 8)
            Button(action: {
                // Handle button tap
            }) {
                Text("Take survey")
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color.white)
        .cornerRadius(12)
    }
}

/// Returns a microsurvey alert view with wrapped text
func microsurveyAlert(_ text: String) -> some View {
    VStack(alignment: .leading) {
        Text("Take our microsurvey")
            .font(.headline)
            .padding(.bottom, 4)
        multiLineTextView(text)
            .padding(.bottom, 8)
        Button(action: {
            // Handle button tap
        }) {
            Text("Take survey")
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
    .background(Color.white)
    .cornerRadius(12)
}