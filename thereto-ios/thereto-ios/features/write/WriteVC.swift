import UIKit
import CropViewController

class WriteVC: BaseVC {
    
    private lazy var writeView = WriteView.init(frame: self.view.frame)
    
    private var viewModel = WriteViewModel.init()

    private let imagePicker = UIImagePickerController()
    
    private var myInfo: User!
    
    var targetUser: User? = nil
    
    
    static func instance(user: User? = nil) -> UINavigationController {
        let controller = WriteVC.init(nibName: nil, bundle: nil)
        
        controller.targetUser = user
        controller.tabBarItem = UITabBarItem.init(title: "엽서쓰기", image: UIImage.init(named: "ic_write"), selectedImage: UIImage.init(named: "ic_write"))
        
        return UINavigationController.init(rootViewController: controller).then {
            $0.modalPresentationStyle = .fullScreen
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.isNavigationBarHidden = true
        view = writeView
        writeView.textField.delegate = self
        imagePicker.delegate = self
        getMyInfo()
        setupKeyboardEvent()
        if let targetUser = targetUser {
            let friend = Friend(user: targetUser)
            
            viewModel.friend.onNext(friend)
        }
    }
    
    override func bindEvent() {
        writeView.tapBg.rx.event.bind { [weak self] _ in
            self?.writeView.endEditing(true)
        }.disposed(by: disposeBag)
        
        writeView.closeBtn.rx.tap.bind { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }.disposed(by: disposeBag)
        
        writeView.friendBtn.rx.tap.bind { [weak self] in
            let selectFriendVC = SelectFriendVC.instance().then {
                $0.delegate = self
            }
            self?.navigationController?.pushViewController(selectFriendVC, animated: true)
        }.disposed(by: disposeBag)
        
        writeView.locationBtn.rx.tap.bind { [weak self] in
            let selectLocationVC = SelectLocationVC.instance().then {
                $0.delegate = self
            }
            self?.navigationController?.pushViewController(selectLocationVC, animated: true)
        }.disposed(by: disposeBag)
        
        writeView.pictureBtn.rx.tap.bind { [weak self] in
            if let vc = self {
                AlertUtil.showImagePicker(controller: vc, picker: vc.imagePicker)
            }
        }.disposed(by: disposeBag)
        
        writeView.pictureImgBtn.rx.tap.bind { [weak self] in
            if let vc = self {
                AlertUtil.showImagePicker(controller: vc, picker: vc.imagePicker)
            }
        }.disposed(by: disposeBag)
        
        writeView.sendBtn.rx.tap.bind { [weak self] in
            if let vc = self {
                if vc.validateContents() {
                    vc.sendLetter()
                }
            }
        }.disposed(by: disposeBag)
    }
    
    override func bindViewModel() {
        viewModel.friend.bind { [weak self] (friend) in
            if let friend = friend {
                self?.writeView.friendBtn.setTitle("\(friend.nickname)", for: .normal)
            }
        }.disposed(by: disposeBag)
        
        viewModel.location.bind { [weak self] (location) in
            if let location = location {
                self?.writeView.locationBtn.setTitle("\(location.name) (\(location.addr))", for: .normal)
            }
        }.disposed(by: disposeBag)
    }
    
    private func getMyInfo() {
        writeView.startLoading()
        UserService.getMyUser { [weak self] (user) in
            self?.myInfo = user
            self?.writeView.stopLoading()
        }
    }
    
    private func setupKeyboardEvent() {
        NotificationCenter.default.addObserver(self, selector: #selector(onShowKeyboard(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(onHideKeyboard(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    private func validateContents() -> Bool {
        let friend = try! viewModel.friend.value()
        
        if friend == nil {
            writeView.showToast(message: "보낼 친구를 선택해주세요.")
            return false
        }
        
        let location = try! viewModel.location.value()
        
        if location == nil {
            writeView.showToast(message: "장소를 선택해주세요.")
            return false
        }
        
        let photo = try! viewModel.mainImg.value()
        
        if photo == nil {
            writeView.showToast(message: "사진을 선택해주세요.")
            return false
        }
        
        if writeView.textField.text!.isEmpty || writeView.textField.text! == "내용을 입력해주세요." {
            writeView.showToast(message: "내용을 입력해주세요.")
            return false
        }
        
        return true
    }
    
    private func sendLetter() {
        writeView.startLoading()
        let photo = try! viewModel.mainImg.value()
        let fileName = "\(UserDefaultsUtil().getUserToken()!)\(DateUtil.date2String(date: Date.init()))"
        
        LetterSerivce.saveLetterPhoto(image: photo!, name: fileName) { [weak self] (result) in
            if let vc = self {
                switch result {
                case .success(let url):
                    let letter = Letter.init(from: vc.myInfo,
                                             to: try! vc.viewModel.friend.value()!,
                                             location: try! vc.viewModel.location.value()!,
                                             photo: url,
                                             message: vc.writeView.textField.text!)
                    LetterSerivce.sendLetter(letter: letter) {
                        // 보낸 편지 카운팅
                        LetterSerivce.increaseSentCount(userId: UserDefaultsUtil().getUserToken()!)
                        // 친구의 받은편지 카운팅
                        LetterSerivce.increaseReceiveCount(userId: try! vc.viewModel.friend.value()!.id)
                        // 친구와 내 프로필에 각각 받은, 보낸편지 카운팅
                        LetterSerivce.increaseFriendCount(userId: try! vc.viewModel.friend.value()!.id)
                        UserService().insertAlarm(userId: try! vc.viewModel.friend.value()!.id, type: .NEW_LETTER)
                        vc.writeView.stopLoading()
                        vc.dismiss(animated: true, completion: nil)
                    }
                case .failure(let error):
                    AlertUtil.show(controller: vc, title: "사진 저장 오류", message: error.localizedDescription)
                    vc.writeView.stopLoading()
                }
            }
        }
    }
    
    private func presentCropViewController(image: UIImage) {
        let cropViewController = CropViewController.init(croppingStyle: .default, image: image)
        
        cropViewController.delegate = self
        cropViewController.aspectRatioLockDimensionSwapEnabled = false
        cropViewController.aspectRatioPreset = .preset4x3
        cropViewController.aspectRatioPickerButtonHidden = true
        cropViewController.aspectRatioLockEnabled = true
        cropViewController.resetButtonHidden = true
        
        present(cropViewController, animated: true, completion: nil)
    }
    
    @objc func onShowKeyboard(notification: NSNotification) {
        let userInfo = notification.userInfo!
        var keyboardFrame:CGRect = (userInfo[UIResponder.keyboardFrameBeginUserInfoKey] as! NSValue).cgRectValue
        keyboardFrame = self.view.convert(keyboardFrame, from: nil)
        
        var contentInset:UIEdgeInsets = self.writeView.scrollView.contentInset
        contentInset.bottom = keyboardFrame.size.height
        self.writeView.scrollView.contentInset = contentInset
    }
    
    @objc func onHideKeyboard(notification: NSNotification) {
        let contentInset:UIEdgeInsets = UIEdgeInsets.zero
        
        self.writeView.scrollView.contentInset = contentInset
    }
}

extension WriteVC: CropViewControllerDelegate {
    func cropViewController(_ cropViewController: CropViewController, didCropToImage image: UIImage, withRect cropRect: CGRect, angle: Int) {
        cropViewController.dismiss(animated: true) {
            self.viewModel.mainImg.onNext(image)
            self.writeView.pictureImgBtn.setImage(image, for: .normal)
        }
    }
}

extension WriteVC: SelectFriendDelegate {
    func onSelectFriend(friend: Friend) {
        self.viewModel.friend.onNext(friend)
    }
}

extension WriteVC: SelectLocationDelegate {
    func onSelectLocation(location: Location) {
        self.viewModel.location.onNext(location)
    }
}

extension WriteVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        if let image = info[.originalImage] as? UIImage {
            self.writeView.pictureBtn.isHidden = true
            self.writeView.pictureImgBtn.isHidden = false
            self.presentCropViewController(image: image)
        }
    }
}

extension WriteVC: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.text == "내용을 입력해주세요." {
            textView.text = ""
            textView.textColor = .greyishBrownTwo
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == "" {
            textView.text = "내용을 입력해주세요."
            textView.textColor = .mushroom
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        guard let textFieldText = textView.text,
            let rangeOfTextToReplace = Range(range, in: textFieldText) else {
                return false
        }
        let substringToReplace = textFieldText[rangeOfTextToReplace]
        let count = textFieldText.count - substringToReplace.count + text.count
        
        return count <= 100
    }
}

