require 'spec_helper'

module Flatter::Extensions
  ::Flatter.configure do |f|
    f.use :order
    f.use :skipping
    f.use :active_record
  end

  module ActiveRecordSpec
    User = SpecModel(:users, email: :string!) do
      has_one :person, class_name: 'Flatter::Extensions::ActiveRecordSpec::Person'
      has_many :phones, class_name: 'Flatter::Extensions::ActiveRecordSpec::Phone'
      has_many :user_roles, class_name: 'Flatter::Extensions::ActiveRecordSpec::UserRole', dependent: :delete_all
      has_many :roles, through: :user_roles, class_name: 'Flatter::Extensions::ActiveRecordSpec::Role'
    end

    UserRole = SpecModel(:user_roles, user_id: :integer, role_id: :integer) do
      belongs_to :user, class_name: 'Flatter::Extensions::ActiveRecordSpec::User'
      belongs_to :role, class_name: 'Flatter::Extensions::ActiveRecordSpec::Role'
    end

    Role = SpecModel(:roles, user_id: :integer, name: :string) do
      has_many :user_roles, class_name: 'Flatter::Extensions::ActiveRecordSpec::UserRole', dependent: :delete_all
      has_many :users, through: :user_roles, class_name: 'Flatter::Extensions::ActiveRecordSpec::User'
    end

    Person = SpecModel(:people, user_id: :integer, first_name: :string, last_name: :string) do
      belongs_to :user, class_name: 'Flatter::Extensions::ActiveRecordSpec::User'
    end

    Phone = SpecModel(:phones, user_id: :integer, number: :string) do
      belongs_to :user, class_name: 'Flatter::Extensions::ActiveRecordSpec::User'

      validates_inclusion_of :number, in: ['111-222-3333', '333-222-1111', '222-333-1111', '222-111-3333']

      before_create :set_ext
      attr_reader :ext

      def set_ext
        @ext = 111
      end
    end

    class UserMapper < ::Flatter::Mapper
      map user_email: :email,
        writer: -> (value){ target.email = value.blank? ? nil : value }

      validates_presence_of :user_email

      trait :registration do
        mount :person, foreign_key: :user_id
        mount :phone, foreign_key: :user_id
      end

      trait :management do
        mount :person, foreign_key: :user_id
        mount :phones, foreign_key: :user_id do
          key :id
        end
      end

      trait :with_roles do
        map :role_ids,
          writer: -> (value){ target.role_ids = value.split(',') }
      end
    end

    class PersonMapper < ::Flatter::Mapper
      map :first_name, :last_name

      validates_presence_of :last_name
    end

    class PhoneMapper < ::Flatter::Mapper
      map phone_number: :number
    end
  end

  RSpec.describe ActiveRecord do
    describe 'general behavior' do
      let!(:user_role)    { ActiveRecordSpec::Role.create(id: 1, name: 'User') }
      let!(:manager_role) { ActiveRecordSpec::Role.create(id: 2, name: 'Manager') }
      let!(:admin_role)   { ActiveRecordSpec::Role.create(id: 3, name: 'Admin') }
      let(:user)   { ActiveRecordSpec::User.create(email: 'spec@mail.com', role_ids: [1]) }
      let(:mapper) { ActiveRecordSpec::UserMapper.new(user, :with_roles) }

      after do
        ActiveRecordSpec::Role.destroy_all
        ActiveRecordSpec::User.destroy_all
      end

      it 'uses transaction on #apply method call' do
        expect(::ActiveRecord::Base).to receive(:transaction).at_least(:once).and_call_original

        expect(mapper.apply(user_email: '', role_ids: '2,3')).to be false
        expect(user.reload.role_ids).to eq [1]
      end

      it 'uses transaction on #save method call' do
        expect(::ActiveRecord::Base).to receive(:transaction).at_least(:once).and_call_original

        mapper.write(user_email: '')
        expect(mapper.save).to be false
        expect(user.reload.email).to eq 'spec@mail.com'
      end
    end

    describe 'user registration and management scenario' do
      let(:new_user) { ActiveRecordSpec::User.new }
      let(:mapper)   { ActiveRecordSpec::UserMapper.new(new_user, :registration) }
      let(:registration_params) do
        { user_email:   'user@email.com',
          first_name:   'John',
          last_name:    'Smith',
          phone_number: '111-222-3333'}
      end

      describe 'registration trait' do
        it 'creates User record and all nested records' do
          expect_any_instance_of(ActiveRecordSpec::User).to receive(:save).once.and_call_original
          expect_any_instance_of(ActiveRecordSpec::Person).to receive(:save).once.and_call_original
          expect_any_instance_of(ActiveRecordSpec::Phone).to receive(:save).once.and_call_original

          expect { expect { expect {
            expect(mapper.apply(registration_params)).to be true
          }.to change{ ActiveRecordSpec::User.count }.by(1)
          }.to change{ ActiveRecordSpec::Person.count }.by(1)
          }.to change{ ActiveRecordSpec::Phone.count }.by(1)
        end

        describe 'nested models' do
          let(:user) { ActiveRecordSpec::User.last }
          before     { mapper.apply(registration_params) }

          specify 'created with proper attributes' do
            expect(user.email).to eq 'user@email.com'
            expect(user.person.first_name).to eq 'John'
            expect(user.person.last_name).to eq 'Smith'
            expect(user.phones.first.number).to eq '111-222-3333'
          end
        end
      end

      describe 'management trait' do
        let(:user)    { ActiveRecordSpec::User.create(email: 'user@email.com') }
        let!(:person) { ActiveRecordSpec::Person.create(user: user, first_name: 'John', last_name: 'Smith') }
        let!(:phones) do
          ['111-222-3333', '333-222-1111'].map do |number|
            ActiveRecordSpec::Phone.create!(user: user, number: number)
          end
          user.phones
        end
        let!(:phone_ids) { phones.map(&:id) }

        let(:mapper) { ActiveRecordSpec::UserMapper.new(user, :management) }

        it 'reads collection properly' do
          expect(mapper.phones).to be_an_instance_of(Array)
          expect(mapper.phones.map{ |ph| ph['key'] }).to eq phones.map(&:id)
        end

        context 'writing data' do
          let(:params) do
            { last_name: 'Smith Jr',
              phones: [{
                key: phone_ids[1], phone_number: '111-222-3333'
              }, {
                phone_number: '222-333-1111'
              }, {
                phone_number: '222-111-3333'
              }] }
          end

          subject(:apply) { mapper.apply(params) }

          it 'updates person' do
            expect{ apply }.
              to change{ person.reload.last_name }.from('Smith').to('Smith Jr')
          end

          it 'updates phones' do
            expect{ apply }.to change{ phones.count }.from(2).to(3)

            expect(ActiveRecordSpec::Phone.find_by(id: phone_ids[0])).to be nil
            expect(ActiveRecordSpec::Phone.find(phone_ids[1]).number).to eq '111-222-3333'
            expect(user.reload.phones.pluck(:number)).
              to match_array ['111-222-3333', '222-333-1111', '222-111-3333']
          end
        end
      end
    end

    describe 'people management scenario' do
      let(:person) { ActiveRecordSpec::Person.new }
      let(:mapper) do
        ActiveRecordSpec::PersonMapper.new(person) do
          mount :user, mounter_foreign_key: :user_id, index: {save: -1} do
            mount :phone, foreign_key: :user_id
          end

          set_callback :validate, :before, :skip_empty

          def skip_empty
            mounting(:user).skip! if user_email.blank?
            mounting(:phone).skip! if mounting(:user).skipped? || phone_number.blank?
          end
        end
      end

      subject(:apply) { mapper.apply(params) }

      context 'with empty params' do
        let(:params) { {} }

        it 'does not create any record' do
          expect { expect { expect {
            expect(apply).to be false
            expect(mapper.errors.keys).to eq [:last_name]
          }.not_to change(ActiveRecordSpec::User, :count)
          }.not_to change(ActiveRecordSpec::Person, :count)
          }.not_to change(ActiveRecordSpec::Phone, :count)
        end
      end

      context 'when only person fields are specified' do
        let(:params) { {last_name: 'Smith', first_name: 'John'} }

        it 'creates only person record' do
          expect { expect { expect {
            expect(apply).to be true
          }.not_to change(ActiveRecordSpec::User, :count)
          }.to change(ActiveRecordSpec::Person, :count).by(1)
          }.not_to change(ActiveRecordSpec::Phone, :count)
        end
      end

      context 'when person and phone number fields are specified' do
        let(:params) { {last_name: 'Smith', first_name: 'John', phone_number: '123-456-7890'} }

        it 'creates only person record' do
          expect { expect { expect {
            expect(apply).to be true
          }.not_to change(ActiveRecordSpec::User, :count)
          }.to change(ActiveRecordSpec::Person, :count).by(1)
          }.not_to change(ActiveRecordSpec::Phone, :count)
        end
      end

      context 'when person and user fields are specified' do
        let(:params) { {last_name: 'Smith', first_name: 'John', user_email: 'user@email.com'} }

        it 'creates user and person records' do
          expect { expect { expect {
            expect(apply).to be true
          }.to change(ActiveRecordSpec::User, :count).by(1)
          }.to change(ActiveRecordSpec::Person, :count).by(1)
          }.not_to change(ActiveRecordSpec::Phone, :count)

          user = ActiveRecordSpec::User.last
          expect(user.email).to eq 'user@email.com'
          expect(user.person.first_name).to eq 'John'
          expect(user.person.last_name).to eq 'Smith'
        end
      end

      context 'when all fields are specified' do
        let(:params) do
          { last_name:    'Smith',
            first_name:   'John',
            user_email:   'user@email.com',
            phone_number: '111-222-3333' }
        end

        it 'creates user, person and phone records' do
          expect { expect { expect {
            expect(apply).to be true
          }.to change(ActiveRecordSpec::User, :count).by(1)
          }.to change(ActiveRecordSpec::Person, :count).by(1)
          }.to change(ActiveRecordSpec::Phone, :count).by(1)

          user = ActiveRecordSpec::User.last
          expect(user.email).to eq 'user@email.com'
          expect(user.person.first_name).to eq 'John'
          expect(user.person.last_name).to eq 'Smith'
          expect(user.phones.first.number).to eq '111-222-3333'
          expect(user.created_at).to be_present
          expect(user.updated_at).to be_present
          expect(user.person.created_at).to be_present
          expect(user.person.updated_at).to be_present
          expect(user.phones.first.created_at).to be_present
          expect(user.phones.first.updated_at).to be_present
        end
      end
    end
  end
end
