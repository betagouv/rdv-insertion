describe RdvContext do
  describe "#action_required" do
    subject { described_class.action_required(number_of_days_before_action_required) }

    let!(:number_of_days_before_action_required) { 4 }

    context "when status requires action" do
      let!(:rdv_context) { create(:rdv_context, status: "rdv_noshow") }

      it "retrieves the rdv_context" do
        expect(subject).to include(rdv_context)
      end
    end

    context "when status does not require action nor attention" do
      let!(:rdv_context) { create(:rdv_context, status: "rdv_seen") }

      it "does not retrieve the rdv_context" do
        expect(subject).not_to include(rdv_context)
      end
    end

    context "when status needs attention" do
      let!(:rdv_context) { create(:rdv_context, status: "invitation_pending") }

      context "when the user has been invited less than 3 days ago in this context" do
        let!(:invitation) { create(:invitation, rdv_context: rdv_context, created_at: 5.days.ago) }
        let!(:invitation2) { create(:invitation, rdv_context: rdv_context, created_at: 2.hours.ago) }

        it "does not retrieve the rdv_context" do
          expect(subject).not_to include(rdv_context)
        end
      end

      context "when the user has been last invited manually more than 3 days ago in this context" do
        let!(:invitation) { create(:invitation, rdv_context: rdv_context, created_at: 5.days.ago) }
        let!(:invitation2) { create(:invitation, rdv_context: rdv_context, created_at: 4.days.ago) }
        let!(:invitation3) { create(:invitation, reminder: true, rdv_context: rdv_context, created_at: 1.day.ago) }

        it "retrieve the rdv_context" do
          expect(subject).to include(rdv_context)
        end
      end
    end
  end

  describe "#set_status" do
    subject { rdv_context.set_status }

    context "closed" do
      context "when closed_at is present" do
        let!(:rdv_context) { create(:rdv_context, closed_at: Time.zone.now) }

        it "is closed" do
          expect(subject).to eq(:closed)
        end
      end
    end

    context "without rdvs" do
      context "without invitations or rdvs" do
        let!(:rdv_context) { create(:rdv_context, rdvs: [], invitations: []) }

        it "is not invited" do
          expect(subject).to eq(:not_invited)
        end
      end

      context "with no sent invitation" do
        let!(:rdv_context) { create(:rdv_context, rdvs: []) }

        it "is not invited" do
          expect(subject).to eq(:not_invited)
        end
      end

      context "with invitations" do
        let!(:user) { create(:user) }
        let!(:invitation) { create(:invitation, user: user, created_at: 2.days.ago) }
        let!(:rdv_context) { create(:rdv_context, user: user, invitations: [invitation]) }

        context "with no participations" do
          it "is in invitation pending" do
            expect(subject).to eq(:invitation_pending)
          end
        end

        context "with a seen participation" do
          context "when the invitation has been sent after the created participation" do
            let!(:participation) do
              create(
                :participation,
                created_at: 4.days.ago, user: user, rdv_context: rdv_context, status: "seen"
              )
            end

            it "is in invitation pending" do
              expect(subject).to eq(:invitation_pending)
            end
          end

          context "when the participation is created after the invitation" do
            let!(:participation) do
              create(
                :participation,
                created_at: 1.day.ago, user: user, rdv_context: rdv_context, status: "seen"
              )
            end

            it "is the status of the participation" do
              expect(subject).to eq(:rdv_seen)
            end
          end

          context "when the last created participation is seen" do
            let!(:rdv) { create(:rdv, starts_at: 4.days.ago) }
            let!(:participation) do
              create(
                :participation,
                created_at: 1.day.ago, rdv: rdv, user: user, rdv_context: rdv_context, status: "seen"
              )
            end
            let!(:other_participation) do
              create(:participation, created_at: 2.days.ago, rdv_context: rdv_context, status: "revoked")
            end

            it "is the status of the participation" do
              expect(subject).to eq(:rdv_seen)
            end
          end

          context "cancelled participation created after the seen participation but before the start of the seen rdv" do
            let!(:rdv) { create(:rdv, starts_at: 1.day.ago) }
            let!(:participation) do
              create(
                :participation,
                created_at: 3.days.ago, rdv: rdv, user: user, rdv_context: rdv_context, status: "seen"
              )
            end
            let!(:other_participation) do
              create(:participation, created_at: 2.days.ago, rdv_context: rdv_context, status: "revoked")
            end

            it "is the status of the participation" do
              expect(subject).to eq(:rdv_seen)
            end
          end
        end

        context "when a participation is pending" do
          let!(:rdv) do
            create(:rdv, starts_at: 2.days.from_now)
          end

          let!(:participation) do
            create(
              :participation,
              created_at: 4.days.ago, rdv: rdv, user: user, rdv_context: rdv_context, status: "unknown"
            )
          end

          it "is pending" do
            expect(subject).to eq(:rdv_pending)
          end
        end

        context "with a cancelled rdv" do
          context "when the invitation has been sent after the participation creation" do
            let!(:rdv) { create(:rdv) }
            let!(:participation) do
              create(
                :participation,
                created_at: 4.days.ago, rdv: rdv, user: user, rdv_context: rdv_context, status: "noshow"
              )
            end

            it "is in invitation pending" do
              expect(subject).to eq(:invitation_pending)
            end
          end

          context "when the invitation has been sent before the participation creation" do
            let!(:rdv) { create(:rdv) }
            let!(:participation) do
              create(
                :participation,
                created_at: 1.day.ago, rdv: rdv, user: user, rdv_context: rdv_context, status: "noshow"
              )
            end

            it "is the status of the participation" do
              expect(subject).to eq(:rdv_noshow)
            end
          end
        end

        context "with mutliple participation after invitation" do
          let!(:invitation) { create(:invitation, created_at: 10.days.ago) }
          let!(:rdv) { create(:rdv, starts_at: 2.days.ago) }
          let!(:participation) do
            create(
              :participation,
              created_at: 4.days.ago, rdv: rdv, user: user, rdv_context: rdv_context, status: "seen"
            )
          end

          let!(:rdv2) { create(:rdv) }
          let!(:participation2) do
            create(
              :participation,
              created_at: 5.days.ago, rdv: rdv2, user: user, rdv_context: rdv_context, status: "noshow"
            )
          end

          it "is the status of the last created participation" do
            expect(subject).to eq(:rdv_seen)
          end

          context "when a rdv is pending" do
            let!(:rdv3) { create(:rdv) }

            let!(:participation3) do
              create(
                :participation,
                created_at: 8.days.ago, rdv: rdv3, user: user, rdv_context: rdv_context, status: "unknown"
              )
            end

            it "is rdv_pending" do
              expect(subject).to eq(:rdv_pending)
            end
          end

          context "when the last rdv is cancelled and one other has been cancelled" do
            let!(:rdv3) { create(:rdv) }
            let!(:participation) do
              create(
                :participation,
                created_at: 1.day.ago, rdv: rdv3, user: user, rdv_context: rdv_context, status: "excused"
              )
            end

            it "is mutliple rdvs cancelled" do
              expect(subject).to eq(:multiple_rdvs_cancelled)
            end
          end

          context "when the last rdv already took place but the status is not updated" do
            let!(:rdv3) do
              create(:rdv, starts_at: 2.days.ago)
            end

            let!(:participation3) do
              create(
                :participation,
                created_at: 1.day.ago, rdv: rdv3, user: user, rdv_context: rdv_context, status: "unknown"
              )
            end

            it "is needs status update" do
              expect(subject).to eq(:rdv_needs_status_update)
            end
          end
        end
      end
    end

    describe "#invited_before_time_window?" do
      let!(:number_of_days_before_action_required) { 4 }

      context "when no rdv" do
        let!(:invitation) { create(:invitation, created_at: 6.days.ago) }
        let!(:invitation2) { create(:invitation, created_at: 1.day.ago) }
        let!(:rdv_context) { create(:rdv_context, invitations: [invitation, invitation2]) }

        context "when invited in time window" do
          it "is false" do
            expect(rdv_context.invited_before_time_window?(number_of_days_before_action_required)).to eq(false)
          end
        end

        context "when not invited in time window" do
          let!(:invitation2) { create(:invitation, created_at: 4.days.ago) }

          it "is true" do
            expect(rdv_context.invited_before_time_window?(number_of_days_before_action_required)).to eq(true)
          end

          context "when there is a reminder" do
            let!(:invitation3) { create(:invitation, rdv_context: rdv_context, reminder: true, created_at: 1.day.ago) }

            it "is not taken into account" do
              expect(rdv_context.invited_before_time_window?(number_of_days_before_action_required)).to eq(true)
            end
          end
        end
      end

      context "when there is a rdv" do
        let!(:user) { create(:user) }
        let!(:rdv) { create(:rdv) }
        let!(:participation) do
          create(:participation, rdv: rdv, user: user, rdv_context: rdv_context, created_at: 5.days.ago)
        end
        let!(:invitation) { create(:invitation, created_at: 6.days.ago) }
        let!(:invitation2) { create(:invitation, created_at: 2.days.ago) }
        let!(:invitation3) { create(:invitation, created_at: 1.day.ago) }
        let!(:rdv_context) do
          create(:rdv_context, status: "invitation_pending", user: user,
                               invitations: [invitation, invitation2, invitation3])
        end

        context "when there is a participation" do
          it "is selecting the invitation after the participation" do
            expect(rdv_context.first_invitation_relative_to_last_participation_created_at).to eq(invitation2.created_at)
          end
        end

        context "when invited in time window" do
          it "is false" do
            expect(rdv_context.invited_before_time_window?(number_of_days_before_action_required)).to eq(false)
          end
        end

        context "when not invited in time window" do
          let!(:invitation2) { create(:invitation, created_at: 4.days.ago) }
          let!(:invitation3) { create(:invitation, created_at: 4.days.ago) }

          it "is true" do
            expect(rdv_context.invited_before_time_window?(number_of_days_before_action_required)).to eq(true)
          end
        end
      end
    end
  end
end
