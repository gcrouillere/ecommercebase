ActiveAdmin.register User, as: 'Clients' do
  actions  :index, :show, :update, :edit
  permit_params :tracking
  menu priority: 7
  config.filters = false

  index do
    column "Prénom - Nom" do |user|
      user.first_name + " " + user.last_name
    end
    column :email
    column "Dernier achat" do |user|
        last_order = Order.where(user: user, state: "paid").order(updated_at: :desc).first
        last_order ? humanized_money(last_order.amount) + " € " + last_order.updated_at.strftime("le %d/%m/%Y") : "Aucun achat"
    end
    column "Total des achats" do |user|
      total = 0
      user_orders = Order.where(user: user, state: "paid")
      nb_achat = Order.where(user: user, state: "paid").size
      user_orders.each do |order|
        total += order.amount
      end
      nb_achat.to_s + " achat(s) : " + humanized_money(total) + " € "
    end
    column "Nb de paniers abandonnés" do |user|
      Order.where(user: user, state: "lost").size
    end
    column "Dernier panier abandonné" do |user|
      last_lost_basket = Order.where(user: user, state: "lost").order(updated_at: :desc).first
      if last_lost_basket
        contenu_panier = last_lost_basket.basketlines.map do |basketline|
          "#{basketline.ceramique.name} - qté: #{basketline.quantity}"
        end
        contenu_panier = contenu_panier.join(", ")
        if last_lost_basket.amount > 0
          humanized_money(last_lost_basket.amount) + " € " + last_lost_basket.updated_at.strftime("le %d/%m/%Y") + ". Il contenait: " + contenu_panier
        else
          "#{last_lost_basket.updated_at.strftime("le %d/%m/%Y")}, supprimé manuellement par le client : contenu inconnu"
        end
      else
        "/"
      end
    end
    actions
  end

  show do |user|
    attributes_table do
      row :first_name
      row :last_name
      row :email
      row "Dernier achat" do |user|
          last_order = Order.where(user: user, state: "paid").order(updated_at: :desc).first
          last_order ? humanized_money(last_order.amount) + " € " + last_order.updated_at.strftime("le %d/%m/%Y") : "Aucun achat"
      end
      row :tracking
    end
  end

  form do |f|
    f.inputs "" do
      f.input :first_name
      f.input :last_name
      f.input :email
      f.input :tracking, :hint => "Entrez le numéro de suivi. Après validation il sera envoyé par mail au client"
    end
    f.actions
  end

  controller do
     def update
      super do |format|
        @user = User.find(params[:id].to_i)
        OrderMailer.send_tracking_after_order(@user).deliver_now
        redirect_to admin_clients_path and return if resource.valid?
      end
    end
  end

  csv do
    column "Prénom" do |user|
      user.first_name
    end
    column "Nom" do |user|
      user.last_name
    end
    column :email
    column "Dernier achat" do |user|
        last_order = Order.where(user: user, state: "paid").order(updated_at: :desc).first
        last_order ? humanized_money(last_order.amount) + " € " + last_order.updated_at.strftime("le %d/%m/%Y") : "Aucun achat"
    end
    column "Total des achats" do |user|
      total = 0
      user_orders = Order.where(user: user, state: "paid")
      user_orders.each do |order|
        total += order.amount
      end
      humanized_money(total) + " € "
    end
    column "Nb de paniers abandonnés" do |user|
      Order.where(user: user, state: "lost").size
    end
    column "Dernier panier abandonné" do |user|
      last_lost_basket = Order.where(user: user, state: "lost").order(updated_at: :desc).first
      if last_lost_basket
        contenu_panier = last_lost_basket.basketlines.map do |basketline|
          "#{basketline.ceramique.name} - qté: #{basketline.quantity}"
        end
        contenu_panier = contenu_panier.join(", ")
        if last_lost_basket.amount > 0
          humanized_money(last_lost_basket.amount) + " € " + last_lost_basket.updated_at.strftime("le %d/%m/%Y") + ". Il contenait: " + contenu_panier
        else
          "#{last_lost_basket.updated_at.strftime("le %d/%m/%Y")}, supprimé manuellement par le client : contenu inconnu"
        end
      else
        "/"
      end
    end
  end

end
