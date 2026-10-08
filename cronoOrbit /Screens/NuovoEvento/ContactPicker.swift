import SwiftUI

#if os(iOS)
import ContactsUI

struct ContactPicker: UIViewControllerRepresentable {
    @Binding var selectedContacts: [String]
    @Binding var selectedEmails: [String]
    
    func makeUIViewController(context: Context) -> CNContactPickerViewController {
        let picker = CNContactPickerViewController()
        picker.delegate = context.coordinator
        
        
        return picker
    }
    
    func updateUIViewController(_ uiViewController: CNContactPickerViewController, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, CNContactPickerDelegate {
        var parent: ContactPicker
        init(_ parent: ContactPicker) { self.parent = parent }

        func contactPicker(_ picker: CNContactPickerViewController, didSelect contacts: [CNContact]) {
            let formatter = CNContactFormatter()
            formatter.style = .fullName
            
            for contact in contacts {
                if let fullName = formatter.string(from: contact) {
                    if !parent.selectedContacts.contains(fullName) {
                        parent.selectedContacts.append(fullName)
                    }
                }
                
                if let email = contact.emailAddresses.first?.value as String? {
                    if !parent.selectedEmails.contains(email) {
                        parent.selectedEmails.append(email)
                    }
                }
            }
        }
    }
}
#endif

