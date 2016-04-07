class HomeController < ShopifyApp::AuthenticatedController
  include Haltable

  def index
    haltable do
      handle_unsuccessful_onboarding
      ensure_shipping_carrier_created
      ensure_shop_updated
      handle_onboarding_if_required

      redirect_to(rates_path)
    end
  end

  def retry
    shop.update_attribute(:shipping_carrier_id, nil)
    redirect_to(root_path)
  end

  private

  def ensure_shipping_carrier_created
    return if shop.shipping_carrier_created?
    CreateShippingCarrierJob.perform_later(shop_domain: shop.shopify_domain)
    onboarding!
  end

  def ensure_shop_updated
    return if shop.has_details?
    ShopUpdateJob.perform_later(shop_domain: shop.shopify_domain)
    onboarding!
  end

  def handle_onboarding_if_required
    return unless onboarding?
    render('onboarding')
    halt
  end

  def handle_unsuccessful_onboarding
    return unless shop.shipping_carrier_error?
    render('error')
    halt
  end

  def onboarding!
    @onboarding = true
  end

  def onboarding?
    @onboarding
  end
end
