require 'spec_helper'

describe "Recipe Model" do
  let(:recipe) { Recipe.new }
  it 'can be created' do
    recipe.should_not be_nil
  end
end
