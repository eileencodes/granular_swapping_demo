require "test_helper"

class DogsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @dog = dogs(:one)
    @dinner = dinners(:one)
  end

  test "just shards" do
    ActiveRecord::Base.connected_to(role: :reading) do
      assert Dog.connected_to?(role: :reading, shard: :default)
      assert Person.connected_to?(role: :reading, shard: :default)
      assert Dinner.connected_to?(role: :reading, shard: :default)

      MealsRecord.connected_to(role: :reading, shard: :one) do
        assert Dog.connected_to?(role: :reading, shard: :default)
        assert Person.connected_to?(role: :reading, shard: :default)
        assert Dinner.connected_to?(role: :reading, shard: :one)
      end

      MealsRecord.connected_to(role: :writing, shard: :two) do
        if ActiveRecord::Base.legacy_connection_handling
          assert Dog.connected_to?(role: :writing, shard: :default)
          assert Person.connected_to?(role: :writing, shard: :default)
        else
          assert Dog.connected_to?(role: :reading, shard: :default)
          assert Person.connected_to?(role: :reading, shard: :default)
        end
        assert Dinner.connected_to?(role: :writing, shard: :two)
      end

      ApplicationRecord.connected_to(role: :writing, shard: :one) do
        if ActiveRecord::Base.legacy_connection_handling
          assert Dog.connected_to?(role: :writing, shard: :default)
          assert Dinner.connected_to?(role: :writing, shard: :default)
        else
          assert Dog.connected_to?(role: :reading, shard: :default)
          assert Dinner.connected_to?(role: :reading, shard: :default)
        end

        assert Person.connected_to?(role: :writing, shard: :one)

        ActiveRecord::Base.connected_to(role: :reading, shard: :default) do
          assert Dog.connected_to?(role: :reading, shard: :default)
          assert Person.connected_to?(role: :reading, shard: :default)
          assert Dinner.connected_to?(role: :reading, shard: :default)
        end
      end
    end
  end

  test "shards" do
    AnimalsRecord.connected_to(role: :reading) do
      assert Dog.connected_to?(role: :reading, shard: :default)
      assert Person.connected_to?(role: :writing, shard: :default)
      assert Dinner.connected_to?(role: :writing, shard: :default)

      MealsRecord.connected_to(role: :writing, shard: :one) do
        assert Dog.connected_to?(role: :reading, shard: :default)
        assert Person.connected_to?(role: :writing, shard: :default)
        assert Dinner.connected_to?(role: :writing, shard: :one)

        ActiveRecord::Base.connected_to(role: :writing, shard: :two) do # global
          assert Dog.connected_to?(role: :writing, shard: :two)
          assert Person.connected_to?(role: :writing, shard: :two)
          assert Dinner.connected_to?(role: :writing, shard: :two)

          AnimalsRecord.connected_to(role: :reading, shard: :default) do
            assert Dog.connected_to?(role: :reading, shard: :default)
            assert Person.connected_to?(role: :writing, shard: :two)
            assert Dinner.connected_to?(role: :writing, shard: :two)
          end

          assert Dog.connected_to?(role: :writing, shard: :two)
          assert Person.connected_to?(role: :writing, shard: :two)
          assert Dinner.connected_to?(role: :writing, shard: :two)
        end

        assert Dog.connected_to?(role: :reading, shard: :default)
        assert Person.connected_to?(role: :writing, shard: :default)
        assert Dinner.connected_to?(role: :writing, shard: :one)
      end

      assert Dog.connected_to?(role: :reading, shard: :default)
      assert Person.connected_to?(role: :writing, shard: :default)
      assert Dinner.connected_to?(role: :writing, shard: :default)
    end
  end

  test "preventing writes" do
    AnimalsRecord.connected_to(role: :reading) do
      assert_raises ActiveRecord::ReadOnlyError do
        Dog.create!
      end
    end
  end

  test "roles" do
    AnimalsRecord.connected_to(role: :reading) do
      assert Dog.connected_to?(role: :reading)
      assert Person.connected_to?(role: :writing)
    end

    assert Dog.connected_to?(role: :writing)
    assert Person.connected_to?(role: :writing)

    ActiveRecord::Base.connected_to(role: :reading) do
      assert Person.connected_to?(role: :reading)
      assert Dog.connected_to?(role: :reading)

      AnimalsRecord.connected_to(role: :writing) do
        assert Person.connected_to?(role: :reading)
        assert Dog.connected_to?(role: :writing)
      end
    end

    assert Dog.connected_to?(role: :writing)
    assert Person.connected_to?(role: :writing)

    AnimalsRecord.connected_to(role: :reading) do
      assert Dog.connected_to?(role: :reading)

      ActiveRecord::Base.connected_to(role: :writing) do
        assert Person.connected_to?(role: :writing)
        assert Dog.connected_to?(role: :writing)
      end

      assert Dog.connected_to?(role: :reading)
      assert Person.connected_to?(role: :writing)

      AnimalsRecord.connected_to(role: :reading) do
        assert Dog.connected_to?(role: :reading)
      end

      assert Dog.connected_to?(role: :reading)

      AnimalsRecord.connected_to(role: :writing) do
        assert Dog.connected_to?(role: :writing)
      end

      assert Dog.connected_to?(role: :reading)
      assert Person.connected_to?(role: :writing)
    end

    assert Dog.connected_to?(role: :writing)
    assert Person.connected_to?(role: :writing)
  end

  test "multi-db api" do
    ActiveRecord::Base.connected_to_many([ApplicationRecord, AnimalsRecord], role: :reading) do
      assert Person.connected_to?(role: :reading)
      assert Dog.connected_to?(role: :reading)
      assert Dinner.connected_to?(role: :writing)
      assert ActiveRecord::Base.connected_to?(role: :writing)
    end
  end

  test "should get index" do
    get dogs_url
    assert_response :success
  end

  test "should get new" do
    get new_dog_url
    assert_response :success
  end

  test "should create dog" do
    assert_difference('Dog.count') do
      post dogs_url, params: { dog: { name: @dog.name } }
    end

    assert_redirected_to dog_url(Dog.last)
  end

  test "should show dog" do
    get dog_url(@dog)
    assert_response :success
  end

  test "should get edit" do
    get edit_dog_url(@dog)
    assert_response :success
  end

  test "should update dog" do
    patch dog_url(@dog), params: { dog: { name: @dog.name } }
    assert_redirected_to dog_url(@dog)
  end
end
