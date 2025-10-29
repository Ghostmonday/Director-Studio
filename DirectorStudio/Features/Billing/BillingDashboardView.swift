//
//  BillingDashboardView.swift
//  DirectorStudio
//
//  PURPOSE: Comprehensive billing dashboard for users
//

import SwiftUI
import Charts

struct BillingDashboardView: View {
    @StateObject private var billingManager = BillingManager.shared
    @StateObject private var pricingEngine = PricingEngine.shared
    @State private var selectedTab = 0
    @State private var showingPurchaseSheet = false
    @State private var showingSubscriptionSheet = false
    @State private var selectedBundle: PricingEngine.PAYGBundle?
    @State private var selectedPlan: PricingEngine.SubscriptionPlan?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Balance Overview
                    BalanceCard(balance: billingManager.userBalance)
                    
                    // Quick Actions
                    HStack(spacing: 16) {
                        Button(action: { showingPurchaseSheet = true }) {
                            Label("Buy Tokens", systemImage: "plus.circle.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                        
                        Button(action: { showingSubscriptionSheet = true }) {
                            Label("Subscribe", systemImage: "crown")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.purple)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal)
                    
                    // Tab Selection
                    Picker("View", selection: $selectedTab) {
                        Text("Usage").tag(0)
                        Text("History").tag(1)
                        Text("Settings").tag(2)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding(.horizontal)
                    
                    // Tab Content
                    switch selectedTab {
                    case 0:
                        UsageView()
                    case 1:
                        TransactionHistoryView()
                    case 2:
                        BillingSettingsView()
                    default:
                        EmptyView()
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Billing & Usage")
            .sheet(isPresented: $showingPurchaseSheet) {
                TokenPurchaseSheet(selectedBundle: $selectedBundle)
            }
            .sheet(isPresented: $showingSubscriptionSheet) {
                SubscriptionSheet(selectedPlan: $selectedPlan)
            }
        }
    }
}

// MARK: - Balance Card

struct BalanceCard: View {
    let balance: UserBalance
    
    var body: some View {
        VStack(spacing: 16) {
            // Main balance
            VStack(spacing: 8) {
                Text("Available Tokens")
                    .font(.headline)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .bottom, spacing: 4) {
                    Text("\(Int(balance.totalAvailable))")
                        .font(.system(size: 48, weight: .bold))
                    Text("seconds")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 8)
                }
                
                // Conversion info
                Text("≈ \(Int(balance.totalAvailable / 60)) minutes of video")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Balance breakdown
            if balance.subscriptionTokens > 0 {
                HStack(spacing: 24) {
                    VStack(alignment: .leading) {
                        Text("Purchased")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(balance.availableTokens))")
                            .font(.headline)
                    }
                    
                    Divider()
                        .frame(height: 30)
                    
                    VStack(alignment: .leading) {
                        Text("Subscription")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("\(Int(balance.subscriptionTokens))")
                            .font(.headline)
                            .foregroundColor(.purple)
                    }
                    
                    if let renewDate = balance.subscriptionRenewDate {
                        Divider()
                            .frame(height: 30)
                        
                        VStack(alignment: .leading) {
                            Text("Renews")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text(renewDate, style: .date)
                                .font(.headline)
                        }
                    }
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.systemGray6))
        .cornerRadius(16)
        .padding(.horizontal)
    }
}

// MARK: - Usage View

struct UsageView: View {
    @StateObject private var billingManager = BillingManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            let usage = billingManager.getMonthlyUsage()
            
            // Monthly usage card
            VStack(alignment: .leading, spacing: 16) {
                Text("This Month")
                    .font(.headline)
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("\(Int(usage.tokensUsed)) tokens used")
                            .font(.title3)
                            .fontWeight(.semibold)
                        Text("\(usage.generationCount) videos generated")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if usage.estimatedCost > 0 {
                        VStack(alignment: .trailing) {
                            Text("$\(String(format: "%.2f", usage.estimatedCost))")
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("overage")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
            .padding(.horizontal)
            
            // Quality breakdown
            if !usage.qualityBreakdown.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Quality Breakdown")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    ForEach(Array(usage.qualityBreakdown.sorted(by: { $0.value > $1.value })), id: \.key) { tier, tokens in
                        HStack {
                            Label(tier.rawValue, systemImage: "film")
                                .font(.subheadline)
                            
                            Spacer()
                            
                            Text("\(Int(tokens)) tokens")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Usage trend chart placeholder
            VStack(alignment: .leading, spacing: 12) {
                Text("Usage Trend")
                    .font(.headline)
                
                // Placeholder for chart
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .frame(height: 200)
                    .overlay(
                        Text("Chart coming soon")
                            .foregroundColor(.secondary)
                    )
            }
            .padding(.horizontal)
        }
    }
}

// MARK: - Transaction History

struct TransactionHistoryView: View {
    @StateObject private var billingManager = BillingManager.shared
    
    var body: some View {
        VStack(spacing: 16) {
            let transactions = billingManager.getTransactionHistory()
            
            if transactions.isEmpty {
                ContentUnavailableView(
                    "No Transactions",
                    systemImage: "doc.text",
                    description: Text("Your transaction history will appear here")
                )
                .padding(.top, 50)
            } else {
                ForEach(transactions) { transaction in
                    TransactionRow(transaction: transaction)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct TransactionRow: View {
    let transaction: BillingTransaction
    
    var body: some View {
        HStack {
            // Icon
            Image(systemName: iconForType(transaction.type))
                .font(.title2)
                .foregroundColor(colorForType(transaction.type))
                .frame(width: 40, height: 40)
                .background(colorForType(transaction.type).opacity(0.1))
                .cornerRadius(8)
            
            // Details
            VStack(alignment: .leading, spacing: 4) {
                Text(transaction.description)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(transaction.timestamp, style: .relative)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                if transaction.amount > 0 {
                    Text("$\(String(format: "%.2f", transaction.amount))")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
                
                if transaction.tokens > 0 {
                    Text("\(Int(transaction.tokens)) tokens")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func iconForType(_ type: BillingTransaction.TransactionType) -> String {
        switch type {
        case .purchase: return "plus.circle.fill"
        case .subscription: return "crown"
        case .generation: return "sparkles"
        case .overage: return "exclamationmark.triangle"
        case .refund: return "arrow.uturn.left.circle"
        case .bonus: return "gift"
        }
    }
    
    private func colorForType(_ type: BillingTransaction.TransactionType) -> Color {
        switch type {
        case .purchase: return .blue
        case .subscription: return .purple
        case .generation: return .green
        case .overage: return .orange
        case .refund: return .red
        case .bonus: return .pink
        }
    }
}

// MARK: - Billing Settings

struct BillingSettingsView: View {
    @StateObject private var billingManager = BillingManager.shared
    
    var body: some View {
        VStack(spacing: 20) {
            // Subscription info
            if let subscription = billingManager.activeSubscription {
                VStack(alignment: .leading, spacing: 16) {
                    Label("Active Subscription", systemImage: "crown")
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(subscription.name)
                                .font(.title3)
                                .fontWeight(.semibold)
                            Text("$\(String(format: "%.2f", subscription.monthlyPrice))/month")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Manage") {
                            // Open subscription management
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding()
                .background(Color.purple.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }
            
            // Settings toggles
            Form {
                Section {
                    Toggle("Allow Overage Billing", isOn: $billingManager.userBalance.allowOverage)
                        .onChange(of: billingManager.userBalance.allowOverage) { _, _ in
                            // Save setting
                        }
                } footer: {
                    Text("When enabled, you can continue generating videos beyond your subscription limit at the overage rate")
                }
                
                Section("Payment Methods") {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "creditcard")
                            Text("Manage Payment Methods")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Billing History") {
                    Button(action: {}) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Download Invoices")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxHeight: 400)
        }
    }
}

// MARK: - Purchase Sheets

struct TokenPurchaseSheet: View {
    @Binding var selectedBundle: PricingEngine.PAYGBundle?
    @StateObject private var pricingEngine = PricingEngine.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Choose a Token Bundle")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    let bundles = pricingEngine.getPAYGBundles(for: .standard)
                    
                    ForEach(bundles) { bundle in
                        BundleCard(bundle: bundle, isSelected: selectedBundle?.id == bundle.id) {
                            selectedBundle = bundle
                        }
                    }
                    
                    if let selected = selectedBundle {
                        VStack(spacing: 16) {
                            Button(action: {
                                // Process purchase
                                dismiss()
                            }) {
                                HStack {
                                    Text("Purchase for $\(String(format: "%.2f", selected.finalPrice))")
                                    Image(systemName: "lock.fill")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                            }
                            
                            Text("Secure payment via Stripe")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Buy Tokens")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BundleCard: View {
    let bundle: PricingEngine.PAYGBundle
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bundle.displayName)
                            .font(.headline)
                        Text("\(bundle.seconds / 60) minutes of video")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("$\(String(format: "%.2f", bundle.finalPrice))")
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        if bundle.discountPercent > 0 {
                            HStack(spacing: 4) {
                                Text("Save \(Int(bundle.discountPercent))%")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 2)
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                
                HStack {
                    Text("$\(String(format: "%.3f", bundle.pricePerSecond))/sec")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    if bundle.seconds >= 600 {
                        Label("Best Value", systemImage: "star.fill")
                            .font(.caption)
                            .foregroundColor(.orange)
                    }
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.blue.opacity(0.05) : Color(.systemBackground))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

struct SubscriptionSheet: View {
    @Binding var selectedPlan: PricingEngine.SubscriptionPlan?
    @StateObject private var pricingEngine = PricingEngine.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Choose a Subscription")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.top)
                    
                    ForEach(pricingEngine.subscriptionPlans) { plan in
                        SubscriptionPlanCard(plan: plan, isSelected: selectedPlan?.id == plan.id) {
                            selectedPlan = plan
                        }
                    }
                }
            }
            .navigationTitle("Subscribe")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SubscriptionPlanCard: View {
    let plan: PricingEngine.SubscriptionPlan
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(plan.name)
                            .font(.title3)
                            .fontWeight(.bold)
                        
                        Text("$\(String(format: "%.2f", plan.monthlyPrice))/month")
                            .font(.headline)
                    }
                    
                    Spacer()
                    
                    if plan.name == "Pro" {
                        Text("POPULAR")
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                
                // Included tokens
                HStack {
                    Image(systemName: "film")
                    Text("\(plan.includedSeconds / 60) minutes included")
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                
                // Features
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(plan.features, id: \.self) { feature in
                        HStack {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                                .font(.caption)
                            Text(feature)
                                .font(.caption)
                        }
                    }
                }
                
                // Overage info
                if plan.overageRate > 0 {
                    Text("Overage: $\(String(format: "%.3f", plan.overageRate))/sec")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.purple : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(isSelected ? Color.purple.opacity(0.05) : Color(.systemBackground))
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .padding(.horizontal)
    }
}

#Preview {
    BillingDashboardView()
}
