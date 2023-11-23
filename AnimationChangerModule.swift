import UIKit
import Lottie

protocol AnimationChanger {
    func registerAnimationContainer(view: UIView)
    func updateAnimation(animation: String)
}

class AnimationChangerModule {
    private var containerViews: [ContainerSmartSubscription] = []
    private var currentAnimation = ""

    var animationLottieView: LottieAnimationView?

    private func updateAnimations() {
        containerViews = containerViews.filter { $0.view != nil }
        containerViews.forEach { setupAnimationFor($0.view) }
    }

    private func setupAnimationFor(_ view: UIView?) {
        guard let view, currentAnimation != "" else { return }

        animationLottieView = .init(name: currentAnimation)
        animationLottieView?.frame = view.bounds
        animationLottieView?.contentMode = .scaleAspectFill
        animationLottieView?.loopMode = .loop
        animationLottieView?.animationSpeed = 1

        view.subviews.forEach({ $0.removeFromSuperview() })
        view.addSubview(animationLottieView!)

        animationLottieView?.play()
    }
}

extension AnimationChangerModule: AnimationChanger {
    func registerAnimationContainer(view: UIView) {
        containerViews.append(ContainerSmartSubscription(view: view))
        setupAnimationFor(view)
    }

    func updateAnimation(animation: String) {
        currentAnimation = animation
        updateAnimations()
    }
}

private struct ContainerSmartSubscription {
    weak var view: UIView?
}
