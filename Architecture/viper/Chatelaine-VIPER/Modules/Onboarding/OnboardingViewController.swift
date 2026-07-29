//
//  OnboardingViewController.swift
//  Chatelaine-VIPER
//
//  Created by Sarah Clark on 7/29/26.
//

import UIKit

/// A passive, paged introduction to the app. It renders the pages it is given and forwards taps and
/// scrolls, deciding nothing about what comes next.
///
/// The page transition and the icon spring are routed through `MotionManager`, so they play only
/// when both the system Reduce Motion setting and the in app toggle allow it, and otherwise the end
/// state is applied instantly.
final class OnboardingViewController: UIViewController, OnboardingViewInput, UIScrollViewDelegate {

    private let output: OnboardingViewOutput

    private let gradientLayer = CAGradientLayer()
    private let scrollView = UIScrollView()
    private let pagesStack = UIStackView()
    private let pageControl = UIPageControl()
    private let continueButton = UIButton(type: .system)
    private let skipButton = UIButton(type: .system)

    private var pageIcons: [UIImageView] = []
    private var viewModel: OnboardingViewModel?

    init(output: OnboardingViewOutput) {
        self.output = output
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not used, this controller is built in code")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // This surface is always the dark brand gradient, so pin the appearance to dark. That keeps
        // the semantic and palette colors resolving to their light-on-dark variants, which avoids
        // dark text on the dark background in Light mode.
        overrideUserInterfaceStyle = .dark
        configureBackground()
        configureScrollView()
        configureControls()
        output.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        springCurrentIcon()
    }

    // MARK: - OnboardingViewInput

    func display(_ viewModel: OnboardingViewModel) {
        self.viewModel = viewModel
        pageControl.numberOfPages = viewModel.pages.count
        buildPages(viewModel.pages)
        updateContinueTitle(forPage: 0)
        skipButton.setTitle(viewModel.skipTitle, for: .normal)
    }

    func goToPage(_ index: Int, animated: Bool) {
        let offset = CGPoint(x: CGFloat(index) * scrollView.bounds.width, y: 0)
        scrollView.setContentOffset(offset, animated: animated)
        if !animated {
            pageControl.currentPage = index
            updateContinueTitle(forPage: index)
        }
    }

    // MARK: - UIScrollViewDelegate

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard scrollView.bounds.width > 0 else { return }
        let page = Int((scrollView.contentOffset.x / scrollView.bounds.width).rounded())
        if page != pageControl.currentPage {
            pageControl.currentPage = page
            updateContinueTitle(forPage: page)
            springCurrentIcon()
        }
    }

    // MARK: - Setup

    private func configureBackground() {
        gradientLayer.colors = [Palette.brandNavy.cgColor, Palette.brandCharcoal.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)
    }

    private func configureScrollView() {
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.delegate = self
        scrollView.accessibilityIdentifier = AccessibilityIdentifiers.Onboarding.pageControl + ".scroll"
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        pagesStack.axis = .horizontal
        pagesStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(pagesStack)

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            pagesStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            pagesStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            pagesStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            pagesStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            pagesStack.heightAnchor.constraint(equalTo: scrollView.frameLayoutGuide.heightAnchor)
        ])
    }

    private func configureControls() {
        pageControl.currentPageIndicatorTintColor = Palette.accent
        pageControl.pageIndicatorTintColor = Palette.textSecondary
        pageControl.accessibilityIdentifier = AccessibilityIdentifiers.Onboarding.pageControl
        pageControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(pageControl)

        skipButton.setTitleColor(Palette.textSecondary, for: .normal)
        skipButton.titleLabel?.font = Typography.font(.subheadline)
        skipButton.titleLabel?.adjustsFontForContentSizeCategory = true
        skipButton.accessibilityIdentifier = AccessibilityIdentifiers.Onboarding.skipButton
        skipButton.addAction(UIAction { [weak self] _ in self?.output.didTapSkip() }, for: .touchUpInside)
        skipButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(skipButton)

        // A Liquid Glass call to action, floating above the content layer.
        let glass = GlassStyling.glassBackground(cornerRadius: 28)
        glass.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(glass)

        continueButton.setTitleColor(Palette.accent, for: .normal)
        continueButton.titleLabel?.font = Typography.font(.headline, weight: .semibold)
        continueButton.titleLabel?.adjustsFontForContentSizeCategory = true
        continueButton.accessibilityIdentifier = AccessibilityIdentifiers.Onboarding.continueButton
        continueButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            output.didTapContinue(currentPage: pageControl.currentPage)
        }, for: .touchUpInside)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(continueButton)

        NSLayoutConstraint.activate([
            skipButton.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            skipButton.trailingAnchor.constraint(equalTo: view.layoutMarginsGuide.trailingAnchor),

            glass.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            glass.bottomAnchor.constraint(equalTo: pageControl.topAnchor, constant: -24),
            glass.widthAnchor.constraint(greaterThanOrEqualToConstant: 220),
            glass.heightAnchor.constraint(equalToConstant: 56),

            continueButton.centerXAnchor.constraint(equalTo: glass.centerXAnchor),
            continueButton.centerYAnchor.constraint(equalTo: glass.centerYAnchor),
            continueButton.leadingAnchor.constraint(equalTo: glass.leadingAnchor, constant: 24),
            continueButton.trailingAnchor.constraint(equalTo: glass.trailingAnchor, constant: -24),

            pageControl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
    }

    // MARK: - Pages

    private func buildPages(_ pages: [OnboardingViewModel.Page]) {
        pagesStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        pageIcons.removeAll()

        for page in pages {
            let (pageView, icon) = makePageView(page)
            // Add to the hierarchy first, so the width constraint against the scroll view has a
            // common ancestor when it is activated.
            pagesStack.addArrangedSubview(pageView)
            pageView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor).isActive = true
            pageIcons.append(icon)
        }
    }

    private func makePageView(_ page: OnboardingViewModel.Page) -> (UIView, UIImageView) {
        let icon = UIImageView(image: UIImage(systemName: page.systemImage))
        icon.tintColor = Palette.accent
        icon.contentMode = .scaleAspectFit
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 72)
        icon.isAccessibilityElement = false

        let title = Typography.label(.largeTitle, weight: .bold)
        title.text = page.title
        title.textColor = Palette.textPrimary
        title.textAlignment = .center

        let body = Typography.label(.body)
        body.text = page.body
        body.textColor = Palette.textSecondary
        body.textAlignment = .center

        let stack = UIStackView(arrangedSubviews: [icon, title, body])
        stack.axis = .vertical
        stack.spacing = 20
        stack.alignment = .center
        stack.translatesAutoresizingMaskIntoConstraints = false

        let container = UIView()
        container.addSubview(stack)
        container.isAccessibilityElement = true
        container.accessibilityLabel = "\(page.title). \(page.body)"
        container.accessibilityTraits = .staticText

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: container.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -32)
        ])
        return (container, icon)
    }

    // MARK: - Motion

    private func springCurrentIcon() {
        let page = pageControl.currentPage
        guard pageIcons.indices.contains(page) else { return }
        let icon = pageIcons[page]
        icon.transform = CGAffineTransform(scaleX: 0.7, y: 0.7)
        icon.alpha = 0.4
        MotionManager.animate(withDuration: 0.45, {
            icon.transform = .identity
            icon.alpha = 1
        })
    }

    private func updateContinueTitle(forPage page: Int) {
        guard let viewModel else { return }
        let isLast = page >= viewModel.pages.count - 1
        continueButton.setTitle(isLast ? viewModel.lastPageTitle : viewModel.continueTitle, for: .normal)
    }
}
